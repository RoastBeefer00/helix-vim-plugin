(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))

(require "helix/editor.scm")
(require "helix/misc.scm")

(require-builtin helix/core/text)

(require "utils.scm")

;; dd
(define (evil-delete-line)
  (helix.static.extend_to_line_bounds)
  (helix.static.delete_selection))

;; dw
(define (evil-delete-word)
  (define pos (cursor-position))
  (helix.static.extend_next_word_start)
  (define new-pos (cursor-position))
  (when (> (- new-pos pos) 1)
    (helix.static.extend_char_right))
  (helix.static.delete_selection))

(provide 
  evil-delete-line
  evil-delete-word
)
