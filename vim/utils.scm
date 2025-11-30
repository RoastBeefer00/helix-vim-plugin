(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))

(require "helix/editor.scm")
(require "helix/misc.scm")

(require-builtin helix/core/text)

(define (get-document-as-slice)
  (let* ([focus (editor-focus)]
         [focus-doc-id (editor->doc-id focus)])
    (editor->text focus-doc-id)))

(define (rope-char-at rope pos)
  (if (and (>= pos 0) (< pos (rope-len-chars rope)))
      (rope-char-ref rope pos)
      #f))

(define (is-whitespace? ch)
  (and ch
       (or (char=? ch #\space)
           (char=? ch #\tab)
           (char=? ch #\newline)
           (char=? ch #\return))))

(define (is-alphabetic? ch)
  (and ch
       (or (and (char>=? ch #\a) (char<=? ch #\z))
           (and (char>=? ch #\A) (char<=? ch #\Z)))))

(define (is-numeric? ch)
  (and ch (char>=? ch #\0) (char<=? ch #\9)))

(define (is-word-char? ch)
  (and ch
       (or (is-alphabetic? ch)
           (is-numeric? ch)
           (char=? ch #\_))))

(define (is-punctuation? ch)
  (and ch
       (not (is-whitespace? ch))
       (not (is-word-char? ch))))

(define (skip-whitespace-forward rope)
  (let ([ch (rope-char-at rope (cursor-position))])
    (when (is-whitespace? ch)
      (helix.static.move_char_right)
      (skip-whitespace-forward rope))))

(define (move-left-n n)
  (when (> n 0)
    (helix.static.move_char_left)
    (move-left-n (- n 1))))

(define (move-right-n n)
  (when (> n 0)
    (helix.static.move_char_right)
    (move-right-n (- n 1))))

(define (do-n-times n func)
  (if (= n 0)
      void
      (begin
        (func)
        (do-n-times (- n 1) func))))

(provide
get-document-as-slice
rope-char-at
is-whitespace?
is-alphabetic?
is-numeric?
is-word-char?
is-punctuation?
skip-whitespace-forward
move-left-n
move-right-n
do-n-times
)
