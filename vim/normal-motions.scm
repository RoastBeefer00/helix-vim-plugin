(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))

(require "helix/misc.scm")
(require "helix/components.scm")

(require-builtin steel/time)
(require-builtin helix/core/text)

(require "utils.scm")

;; a
(define (evil-append-mode)
  ;; Move to insert mode
  (helix.static.insert_mode)
  (helix.static.collapse_selection)
  (helix.static.move_char_right))

;; l
(define (move-char-right-same-line)
  (define pos (cursor-position))
  (define char (rope-char-ref (get-document-as-slice) (+ 1 pos)))
  (when char
    (unless (equal? #\newline char)
      (helix.static.move_char_right))))

;; h
(define (move-char-left-same-line)
  (define pos (cursor-position))
  (define char (rope-char-ref (get-document-as-slice) (- pos 1)))
  (when char
    (unless (equal? #\newline char)
      (helix.static.move_char_left))))

(define (move-line-up-impl)
  (define pos (cursor-position))
  (define doc (get-document-as-slice))
  (define char (rope-char-ref doc pos))
  (when char
    (when (char=? #\newline char)
      (define char-to-left (rope-char-ref doc (- pos 1)))
      (when char-to-left
        (unless (char=? #\newline char-to-left)
          (helix.static.move_char_left))))))

;; k
(define (move-line-up)
  (helix.static.move_line_up)
  (move-line-up-impl))

(define (move-line-down-impl)
  (define pos (cursor-position))
  (define doc (get-document-as-slice))
  (define char (rope-char-ref doc pos))
  (when char
    (when (char=? #\newline char)
      (define char-to-left (rope-char-ref doc (- pos 1)))
      (when char-to-left
        (unless (char=? #\newline char-to-left)
          (helix.static.move_char_left))))))

;; j
(define (move-line-down)
  (helix.static.move_line_down)
  (move-line-down-impl))

;; f(char)
(define (evil-find-next-char)
  (define (loop i next-char)
    (define pos (cursor-position))
    (define doc (get-document-as-slice))
    (define char (rope-char-ref doc (+ i pos)))
    (cond
      [(equal? char #\newline) void]
      ;; Move right n times
      [(equal? char next-char) (do-n-times i helix.static.move_char_right)]
      [else (loop (+ i 1) next-char)]))

  (on-key-callback (lambda (key-event)
                     (define char (on-key-event-char key-event))
                     (when char
                       (loop 1 char)))))

;; F(char)
(define (evil-find-prev-char)
  (define (loop i next-char)
    (define pos (cursor-position))
    (define doc (get-document-as-slice))
    (define char (rope-char-ref doc (- pos i)))
    (cond
      [(equal? char #\newline) void]
      ;; Move right n times
      [(equal? char next-char) (do-n-times i helix.static.move_char_left)]
      [else (loop (+ i 1) next-char)]))

  (on-key-callback (lambda (key-event)
                     (define char (on-key-event-char key-event))
                     (when char
                       (loop 1 char)))))

;; t(char)
(define (evil-find-till-char)
  (define (loop i next-char)
    (define pos (cursor-position))
    (define doc (get-document-as-slice))
    (define char (rope-char-ref doc (+ i pos)))
    (cond
      [(equal? char #\newline) void]
      ;; Move right n times
      [(equal? char next-char)
       (do-n-times i helix.static.move_char_right)
       (helix.static.move_char_left)]
      [else (loop (+ i 1) next-char)]))

  (on-key-callback (lambda (key-event)
                     (define char (on-key-event-char key-event))
                     (when char
                       (loop 0 char)))))

;; T(char)
(define (evil-till-prev-char)
  (define (loop i next-char)
    (define pos (cursor-position))
    (define doc (get-document-as-slice))
    (define char (rope-char-ref doc (- pos i)))
    (cond
      [(equal? char #\newline) void]
      ;; Move right n times
      [(equal? char next-char)
       (do-n-times i helix.static.move_char_left)
       (helix.static.move_char_right)]
      [else (loop (+ i 1) next-char)]))

  (on-key-callback (lambda (key-event)
                     (define char (on-key-event-char key-event))
                     (when char
                       (loop 0 char)))))

;; G or (line-number)G
(define (evil-goto-line-or-last)
  (define rope (get-document-as-slice))
  (define start-pos (cursor-position))
  
  (helix.static.goto_line)
  
  (define end-pos (cursor-position))
  
  ;; If we didn't move, no count was provided - go to last line
  (when (= start-pos end-pos)
    (helix.static.goto_last_line)))

;; e
(define (evil-next-word-end)
  (helix.static.move_next_word_end)
  (helix.static.collapse_selection))

;; E
(define (evil-next-long-word-end)
  (helix.static.move_next_long_word_end)
  (helix.static.collapse_selection))

;; b
(define (evil-prev-word-start)
  (helix.static.move_prev_word_start)
  (helix.static.collapse_selection)
  (define pos (cursor-position))
  (define doc (get-document-as-slice))
  (define cur-char (rope-char-ref doc pos))
  (when (and cur-char (char-whitespace? cur-char))
    (evil-prev-word-start)))

;; B
(define (evil-prev-long-word-start)
  (helix.static.move_prev_long_word_start)
  (helix.static.collapse_selection)
  (define pos (cursor-position))
  (define doc (get-document-as-slice))
  (define cur-char (rope-char-ref doc pos))
  (when (and cur-char (char-whitespace? cur-char))
    (evil-prev-long-word-start)))

;; w
(define (evil-next-word-start)
  (define rope (get-document-as-slice))
  (define start-pos (cursor-position))
  (define len (rope-len-chars rope))
  
  (define cur-char (rope-char-at rope start-pos))
  (define on-whitespace (is-whitespace? cur-char))
  (define on-word (is-word-char? cur-char))
  (define on-punct (is-punctuation? cur-char))
  
  (define (skip-whitespace pos)
    (let loop ([p pos])
      (let ([ch (rope-char-at rope p)])
        (cond
          [(>= p len) len]
          [(is-whitespace? ch) (loop (+ p 1))]
          [else p]))))
  
  (define (find-next-word-start pos)
    (cond
      [(>= pos len) len]
      
      ;; On whitespace: skip to first non-whitespace
      [on-whitespace
       (skip-whitespace pos)]
      
      ;; On word char: skip word chars, then skip whitespace
      [on-word
       (let* ([after-word (let loop ([p pos])
                            (let ([ch (rope-char-at rope p)])
                              (cond
                                [(>= p len) len]
                                [(is-word-char? ch) (loop (+ p 1))]
                                [else p])))]
              [after-space (skip-whitespace after-word)])
         after-space)]
      
      ;; On punctuation: skip punctuation, then skip whitespace
      [on-punct
       (let* ([after-punct (let loop ([p pos])
                             (let ([ch (rope-char-at rope p)])
                               (cond
                                 [(>= p len) len]
                                 [(is-punctuation? ch) (loop (+ p 1))]
                                 [else p])))]
              [after-space (skip-whitespace after-punct)])
         after-space)]
      
      [else pos]))
  
  (define target-pos (find-next-word-start start-pos))
  (when (> target-pos start-pos)
    (move-right-n (- target-pos start-pos))))

;; W
(define (evil-next-long-word-start)
  (define rope (get-document-as-slice))
  (define start-pos (cursor-position))
  (define len (rope-len-chars rope))
  
  (define cur-char (rope-char-at rope start-pos))
  (define on-whitespace (is-whitespace? cur-char))
  
  (define (skip-whitespace pos)
    (let loop ([p pos])
      (let ([ch (rope-char-at rope p)])
        (cond
          [(>= p len) len]
          ;; Stop if we hit a newline (empty line boundary)
          [(and (is-whitespace? ch) (not (char=? ch #\newline)))
           (loop (+ p 1))]
          [(char=? ch #\newline)
           ;; Move past the newline, but stop if next line is empty or has content
           (let ([next-pos (+ p 1)])
             (if (>= next-pos len)
                 len
                 (let ([next-ch (rope-char-at rope next-pos)])
                   (if (char=? next-ch #\newline)
                       ;; Empty line - stop here
                       next-pos
                       ;; Continue skipping whitespace on this line
                       (if (and next-ch (is-whitespace? next-ch) (not (char=? next-ch #\newline)))
                           (loop next-pos)
                           next-pos)))))]
          [else p]))))
  
  (define (skip-non-whitespace pos)
    (let loop ([p pos])
      (let ([ch (rope-char-at rope p)])
        (cond
          [(>= p len) len]
          [(is-whitespace? ch) p]
          [else (loop (+ p 1))]))))
  
  (define (find-next-word-start pos)
    (cond
      [(>= pos len) len]
      
      ;; On whitespace: skip to first non-whitespace
      [on-whitespace
       (skip-whitespace pos)]
      
      ;; On non-whitespace: skip to end, then skip whitespace
      [else
       (let* ([after-word (skip-non-whitespace pos)]
              [after-space (skip-whitespace after-word)])
         after-space)]))
  
  (define target-pos (find-next-word-start start-pos))
  (when (> target-pos start-pos)
    (move-right-n (- target-pos start-pos))))

(provide 
  evil-append-mode
  move-char-right-same-line
  move-char-left-same-line
  move-line-up-impl
  move-line-up
  move-line-down-impl
  move-line-down
  evil-find-next-char
  evil-find-prev-char
  evil-find-till-char
  evil-till-prev-char
  evil-goto-line-or-last
  evil-next-word-start
  evil-next-word-end
  evil-prev-word-start
  evil-prev-long-word-start
  evil-next-long-word-start
  evil-next-long-word-end
)
