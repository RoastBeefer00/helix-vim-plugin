;; oil.scm — oil.nvim-style editable directory buffer for Helix
;;
;; Lines: <id>\t<name>   (dirs get trailing /)
;; Edit names, delete lines, add bare lines (no id prefix), then g w to apply.
;;
;; Keybindings (oil buffer only, normal mode):
;;   <ret>   open file / navigate into directory
;;   -       parent directory
;;   g w     apply pending changes
;;   g r     refresh (discard edits)
;;   g .     toggle hidden files
;;
;; Entry point: :oil-open  (opens at current file's directory or pwd)

(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/misc.scm")
(require "helix/editor.scm")
(require-builtin helix/core/text)

(require (only-in "labelled-buffers.scm"
                  make-new-labelled-buffer!
                  temporarily-switch-focus
                  open-labelled-buffer
                  currently-in-labelled-buffer?
                  maybe-fetch-doc-id
                  fetch-doc-id))

(provide oil-open
         oil-enter
         oil-up
         oil-apply
         oil-refresh
         oil-toggle-hidden
         OIL-BUFFER
         OIL-KEYBINDINGS)

;;; ---- Label ----

(define OIL-BUFFER "github.com/mattwparas/helix-config/oil")

;;; ---- State ----

(define *oil-dir* "")
(define *oil-entries* (hash)) ; id (int) -> display-name string (dirs have trailing /)
(define *oil-id-list* '())    ; ids in rendered order, used to detect deletions
(define *oil-next-id* 0)      ; monotonic; never reset so ids remain unique across refreshes
(define *oil-show-hidden* #f)

;;; ---- Path helpers ----

(define (oil-path-join parent name)
  (if (string=? parent "/")
      (string-append "/" name)
      (string-append parent "/" name)))

(define (oil-parent-of path)
  (define len (string-length path))
  (define (last-slash i)
    (cond [(< i 0) #f]
          [(char=? (string-ref path i) #\/) i]
          [else (last-slash (- i 1))]))
  (define pos (last-slash (- len 1)))
  (cond [(not pos) path]
        [(= pos 0) "/"]
        [else (substring path 0 pos)]))

(define (oil-hidden? name)
  (and (> (string-length name) 0)
       (char=? (string-ref name 0) #\.)))

(define (oil-digit? ch)
  (and (char>=? ch #\0) (char<=? ch #\9)))

(define (oil-ends-slash? s)
  (define len (string-length s))
  (and (> len 0) (char=? (string-ref s (- len 1)) #\/)))

(define (oil-strip-slash s)
  (define len (string-length s))
  (if (oil-ends-slash? s) (substring s 0 (- len 1)) s))

;;; ---- Sort (stable merge sort, same pattern as file-tree.scm) ----

(define (oil-merge l1 l2 key)
  (cond [(null? l1) l2]
        [(null? l2) l1]
        [(string<? (key (car l1)) (key (car l2)))
         (cons (car l1) (oil-merge (cdr l1) l2 key))]
        [else (cons (car l2) (oil-merge (cdr l2) l1 key))]))

(define (oil-split lst)
  (let loop ([l lst] [a '()] [b '()] [flip #t])
    (if (null? l)
        (cons (reverse a) (reverse b))
        (if flip
            (loop (cdr l) (cons (car l) a) b #f)
            (loop (cdr l) a (cons (car l) b) #t)))))

(define (oil-sort lst key)
  (if (or (null? lst) (null? (cdr lst)))
      lst
      (let ([halves (oil-split lst)])
        (oil-merge (oil-sort (car halves) key)
                   (oil-sort (cdr halves) key)
                   key))))

;;; ---- Line parsing ----

(define (parse-oil-line line)
  ; Returns (id . display-name) if line has id-tab prefix, else #f
  (define len (string-length line))
  (define (scan i)
    (cond [(>= i len) #f]
          [(oil-digit? (string-ref line i)) (scan (+ i 1))]
          [(and (> i 0) (char=? (string-ref line i) #\tab))
           (cons (string->number (substring line 0 i))
                 (substring line (+ i 1) len))]
          [else #f]))
  (if (and (> len 0) (oil-digit? (string-ref line 0)))
      (scan 0)
      #f))

;;; ---- Buffer reading ----

(define (oil-get-text)
  (rope->string (editor->text (editor->doc-id (editor-focus)))))

(define (oil-split-lines text)
  (define len (string-length text))
  (let loop ([start 0] [acc '()])
    (define (find-nl i)
      (cond [(>= i len) i]
            [(char=? (string-ref text i) #\newline) i]
            [else (find-nl (+ i 1))]))
    (define nl (find-nl start))
    (define seg (substring text start nl))
    (if (>= nl len)
        (reverse (if (string=? seg "") acc (cons seg acc)))
        (loop (+ nl 1) (cons seg acc)))))

(define (oil-current-line-str)
  (define raw (rope->string (rope->line (editor->text (editor->doc-id (editor-focus)))
                                        (helix.static.get-current-line-number))))
  (define len (string-length raw))
  (if (and (> len 0) (char=? (string-ref raw (- len 1)) #\newline))
      (substring raw 0 (- len 1))
      raw))

;;; ---- Prompt helper ----

(define (helix-prompt! str thunk)
  (push-component! (prompt str thunk)))

;;; ---- Render ----

(define (render-oil!)
  (set! *oil-entries* (hash))

  (define all-paths (read-dir *oil-dir*))
  (define visible
    (if *oil-show-hidden*
        all-paths
        (filter (lambda (p) (not (oil-hidden? (file-name p)))) all-paths)))

  (define dirs  (oil-sort (filter is-dir?  visible) file-name))
  (define files (oil-sort (filter is-file? visible) file-name))
  (define sorted (append dirs files))

  ; Assign IDs and build snapshot before touching the buffer
  (define id-display-pairs
    (map (lambda (path)
           (define id *oil-next-id*)
           (set! *oil-next-id* (+ *oil-next-id* 1))
           (define name (file-name path))
           (define display (if (is-dir? path) (string-append name "/") name))
           (cons id display))
         sorted))

  ; Update module-level snapshot
  (map (lambda (p)
         (set! *oil-entries* (hash-insert *oil-entries* (car p) (cdr p))))
       id-display-pairs)

  (set! *oil-id-list* (map car id-display-pairs))

  ; Clear buffer and write new content
  (helix.static.select_all)
  (helix.static.delete_selection)

  (map (lambda (p)
         (helix.static.insert_string (string-append (to-string (car p)) "\t" (cdr p)))
         (helix.static.open_below)
         (helix.static.goto_line_start))
       id-display-pairs)

  (helix.static.goto_file_start)
  (helix.static.normal_mode))

;;; ---- Buffer management ----

(define (ensure-oil-buffer!)
  (define existing (maybe-fetch-doc-id OIL-BUFFER))
  (when (or (not existing) (not (editor-doc-exists? existing)))
    ; make-new-labelled-buffer! opens a vsplit to create the buffer, then returns focus.
    ; Immediately close that split so oil has no dedicated view of its own —
    ; oil-open will switch the current view in-place instead.
    (define last-focused (editor-focus))
    (define last-mode (editor-mode))
    (make-new-labelled-buffer! #:label OIL-BUFFER)
    (define oil-view (editor-doc-in-view? (fetch-doc-id OIL-BUFFER)))
    (when oil-view
      (editor-set-focus! oil-view)
      (helix.quit))
    (editor-set-focus! last-focused)
    (editor-set-mode! last-mode)))

;;; ---- Public commands ----

(define (oil-open)
  (define path (editor-document->path (editor->doc-id (editor-focus))))
  (define dir
    (cond [(not (string? path)) (helix-find-workspace)]
          [(is-dir? path)       path]
          [else                 (oil-parent-of path)]))
  (set! *oil-dir* dir)
  (ensure-oil-buffer!)
  (editor-switch! (fetch-doc-id OIL-BUFFER))
  (render-oil!))

(define (oil-enter)
  (when (currently-in-labelled-buffer? OIL-BUFFER)
    (define parsed (parse-oil-line (oil-current-line-str)))
    (when parsed
      (define id      (car parsed))
      (define display (cdr parsed))
      (when (hash-try-get *oil-entries* id)
        (define bare (oil-strip-slash display))
        (define full (oil-path-join *oil-dir* bare))
        (if (oil-ends-slash? display)
            (begin
              (set! *oil-dir* full)
              (render-oil!))
            (helix.open full))))))

(define (oil-up)
  (when (currently-in-labelled-buffer? OIL-BUFFER)
    (define new-dir (oil-parent-of *oil-dir*))
    (unless (string=? new-dir *oil-dir*)
      (set! *oil-dir* new-dir)
      (render-oil!))))

(define (oil-refresh)
  (when (currently-in-labelled-buffer? OIL-BUFFER)
    (render-oil!)))

(define (oil-toggle-hidden)
  (when (currently-in-labelled-buffer? OIL-BUFFER)
    (set! *oil-show-hidden* (not *oil-show-hidden*))
    (render-oil!)))

;;; ---- Diff and apply ----

(define (compute-ops lines)
  ; Returns (ops . error-string-or-#f)
  (define non-empty (filter (lambda (l) (not (string=? l ""))) lines))
  (define parsed-results (map parse-oil-line non-empty))

  (define id-pairs (filter pair? parsed-results))

  (define create-names
    (let loop ([ps parsed-results] [ls non-empty] [acc '()])
      (if (null? ps)
          (reverse acc)
          (loop (cdr ps) (cdr ls)
                (if (car ps) acc (cons (car ls) acc))))))

  ; Group id-pairs by id: id -> list of all names seen in buffer for that id
  ; Duplicate ids = copy operations, not errors
  (define id->names
    (let loop ([pairs id-pairs] [acc (hash)])
      (if (null? pairs)
          acc
          (let* ([id       (car (car pairs))]
                 [name     (cdr (car pairs))]
                 [existing (hash-try-get acc id)])
            (loop (cdr pairs)
                  (hash-insert acc id (if existing (cons name existing) (list name))))))))

  ; Walk original id list to produce renames, deletes, and copies
  (define ops
    (let loop ([ids *oil-id-list*] [acc '()])
      (if (null? ids)
          (reverse acc)
          (let* ([id        (car ids)]
                 [old-name  (hash-try-get *oil-entries* id)]
                 [new-names (hash-try-get id->names id)])
            (loop (cdr ids)
                  (cond
                    [(not old-name) acc]
                    ; id absent from buffer → delete
                    [(not new-names)
                     (cons (list 'delete old-name) acc)]
                    ; single occurrence → rename or no-op
                    [(= (length new-names) 1)
                     (if (string=? old-name (car new-names))
                         acc
                         (cons (list 'rename old-name (car new-names)) acc))]
                    ; multiple occurrences → copies (original implicitly kept)
                    [else
                     (define copies
                       (filter (lambda (n) (not (string=? n old-name))) new-names))
                     (append (reverse (map (lambda (n) (list 'copy old-name n)) copies))
                             acc)]))))))

  (define creates
    (map (lambda (name) (list 'create name)) create-names))

  (cons (append ops creates) #f))

(define (format-op op)
  (define kind (car op))
  (cond [(eq? kind 'rename) (string-append "RENAME " (list-ref op 1) " -> " (list-ref op 2))]
        [(eq? kind 'copy)   (string-append "COPY "   (list-ref op 1) " -> " (list-ref op 2))]
        [(eq? kind 'delete) (string-append "DELETE " (list-ref op 1))]
        [(eq? kind 'create) (string-append "CREATE " (list-ref op 1))]))

(define (execute-op! op)
  (define kind (car op))
  (cond
    [(eq? kind 'delete)
     (helix.run-shell-command "rm" "-rf"
                              (oil-path-join *oil-dir* (oil-strip-slash (list-ref op 1))))]
    [(eq? kind 'rename)
     (helix.run-shell-command "mv"
                              (oil-path-join *oil-dir* (oil-strip-slash (list-ref op 1)))
                              (oil-path-join *oil-dir* (oil-strip-slash (list-ref op 2))))]
    [(eq? kind 'copy)
     (helix.run-shell-command "cp" "-r"
                              (oil-path-join *oil-dir* (oil-strip-slash (list-ref op 1)))
                              (oil-path-join *oil-dir* (oil-strip-slash (list-ref op 2))))]
    [(eq? kind 'create)
     (define display (list-ref op 1))
     (define full    (oil-path-join *oil-dir* (oil-strip-slash display)))
     (if (oil-ends-slash? display)
         (hx.create-directory full)
         (temporarily-switch-focus
          (lambda ()
            (helix.vsplit-new)
            (helix.open full)
            (helix.write full)
            (helix.quit))))]))

(define (execute-all-ops! ops)
  (if (null? ops)
      (enqueue-thread-local-callback oil-refresh)
      (begin
        (execute-op! (car ops))
        (execute-all-ops! (cdr ops)))))

(define (oil-apply)
  (when (currently-in-labelled-buffer? OIL-BUFFER)
    (define result (compute-ops (oil-split-lines (oil-get-text))))
    (define ops (car result))
    (define err (cdr result))
    (cond
      [err         (set-status! err)]
      [(null? ops) (set-status! "oil: nothing to apply")]
      [else
       (define op-lines
         (let loop ([os ops] [acc '()])
           (if (null? os)
               (reverse acc)
               (loop (cdr os) (cons (format-op (car os)) acc)))))
       (define summary
         (let loop ([ls op-lines] [s ""])
           (if (null? ls)
               s
               (loop (cdr ls) (string-append s "  " (car ls) "\n")))))
       (helix-prompt!
        (string-append "Apply:\n" summary "Proceed? (y/n) ")
        (lambda (answer)
          (if (string=? answer "y")
              (execute-all-ops! ops)
              (set-status! "oil: cancelled"))))])))

;;; ---- Keybindings ----

(define OIL-KEYBINDINGS
  (hash "normal"
        (hash "ret" ':oil-enter
              "-"   ':oil-up
              "g"   (hash "w" ':oil-apply
                          "r" ':oil-refresh
                          "." ':oil-toggle-hidden))))
