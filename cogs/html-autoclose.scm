;; html-autoclose.scm — insert matching closing tag when > is typed
;;
;; Bind > in insert mode (per file type) to :html-autoclose.
;; Void elements and self-closing tags are skipped.
;;
;; Known limitation: attribute values containing > (e.g. data-x="a>b")
;; will trigger a false positive on that line.

(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")

(provide html-autoclose
         HTML-AUTOCLOSE-KEYBINDINGS)

;;; ---- Void elements ----

(define *void-elements*
  '("area" "base" "br" "col" "embed" "hr" "img" "input"
    "link" "meta" "param" "source" "track" "wbr"))

(define (list-member? item lst)
  (cond [(null? lst) #f]
        [(equal? item (car lst)) #t]
        [else (list-member? item (cdr lst))]))

;;; ---- ASCII helpers ----

(define (char-ascii-downcase ch)
  (if (and (char>=? ch #\A) (char<=? ch #\Z))
      (integer->char (+ (char->integer ch) 32))
      ch))

(define (string-ascii-downcase s)
  (list->string (map char-ascii-downcase (string->list s))))

(define (void-element? tag)
  (list-member? (string-ascii-downcase tag) *void-elements*))

;;; ---- Tag name chars ----

(define (tag-name-char? ch)
  (or (char-alphabetic? ch)
      (char-numeric? ch)
      (char=? ch #\-)
      (char=? ch #\.)
      (char=? ch #\:)))

;;; ---- Current line ----

(define (html-current-line)
  (define raw
    (rope->string (rope->line (editor->text (editor->doc-id (editor-focus)))
                              (helix.static.get-current-line-number))))
  (define len (string-length raw))
  (if (and (> len 0) (char=? (string-ref raw (- len 1)) #\newline))
      (substring raw 0 (- len 1))
      raw))

;;; ---- Tag scanner ----
;;
;; Expects line to already end with the '>' just inserted.
;; Returns opening tag name string, or #f if autoclosing should be skipped.

(define (find-open-tag line)
  (define len (string-length line))
  (and (> len 1)
       (char=? (string-ref line (- len 1)) #\>)
       ; skip self-closing: ends with "/>"
       (not (char=? (string-ref line (- len 2)) #\/))
       ; find last '<' before the '>'
       (let scan-lt ([i (- len 2)])
         (cond
           [(< i 0) #f]
           [(char=? (string-ref line i) #\<)
            (let ([next (and (< (+ i 1) len) (string-ref line (+ i 1)))])
              (if (or (not next)
                      (char=? next #\/)   ; closing tag
                      (char=? next #\!))  ; comment / doctype
                  #f
                  ; extract tag name
                  (let name-scan ([j (+ i 1)] [acc '()])
                    (if (or (>= j len) (not (tag-name-char? (string-ref line j))))
                        (let ([tag (list->string (reverse acc))])
                          (and (> (string-length tag) 0)
                               (not (void-element? tag))
                               tag))
                        (name-scan (+ j 1) (cons (string-ref line j) acc))))))]
           [else (scan-lt (- i 1))]))))

;;; ---- Main command ----

(define (html-autoclose)
  ; Insert the '>' the user typed
  (helix.static.insert_string ">")
  ; Read the updated line and check for an open tag
  (define tag (find-open-tag (html-current-line)))
  (when tag
    (define closing (string-append "</" tag ">"))
    (helix.static.insert_string closing)
    ; Reposition cursor between the tags.
    ; After insert_string in insert mode the cursor is past closing.
    ; normal_mode moves cursor back one (onto last '>' of closing tag).
    ; Then move left (len - 1) to land on '<' of closing tag.
    ; insert_mode puts the insert cursor before '<', i.e. between the tags.
    (helix.static.normal_mode)
    (let loop ([n (- (string-length closing) 1)])
      (when (> n 0)
        (helix.static.move_char_left)
        (loop (- n 1))))
    (helix.static.insert_mode)))

;;; ---- Keybindings ----

(define HTML-AUTOCLOSE-KEYBINDINGS
  (hash "insert" (hash ">" ':html-autoclose)))
