(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))

(require "utils.scm")
(require "key-emulation.scm")
(require "helix/misc.scm")

(require-builtin steel/time)

(require-builtin helix/core/text)

(define (extend-char-right-same-line)
  (define pos (cursor-position))
  (define char (rope-char-ref (get-document-as-slice) (+ 1 pos)))
  (when char
    (unless (equal? #\newline char)
      (helix.static.extend_char_right))))

(define (extend-char-left-same-line)
  (define pos (cursor-position))
  (define char (rope-char-ref (get-document-as-slice) (- pos 1)))
  (when char
    (unless (equal? #\newline char)
      (helix.static.extend_char_left))))

(define (extend-line-up-impl)
  (define pos (cursor-position))
  (define doc (get-document-as-slice))
  (define char (rope-char-ref doc pos))
  (when char
    (when (char=? #\newline char)
      (define char-to-left (rope-char-ref doc (- pos 1)))
      (when char-to-left
        (unless (char=? #\newline char-to-left)
          (helix.static.extend_char_left))))))

(define (extend-line-up)
  (helix.static.extend_line_up)
  (extend-line-up-impl))

(define (extend-line-down-impl)
  (define pos (cursor-position))
  (define doc (get-document-as-slice))
  (define char (rope-char-ref doc pos))
  (when char
    (when (char=? #\newline char)
      (define char-to-left (rope-char-ref doc (- pos 1)))
      (when char-to-left
        (unless (char=? #\newline char-to-left)
          (helix.static.extend_char_left))))))

(define (extend-line-down)
  (helix.static.extend_line_down)
  (extend-line-down-impl))

(define (select-around-word)
  (helix.static.select_textobject_around)
  (trigger-on-key-callback w-key))

(define (select-inner-word)
  (helix.static.select_textobject_inner)
  (trigger-on-key-callback w-key))

(provide 
  extend-char-right-same-line
  extend-char-left-same-line
  extend-line-up
  extend-line-down
  select-around-word
  select-inner-word
)
