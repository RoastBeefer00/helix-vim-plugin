(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))

(require "delete-motions.scm")

(require-builtin steel/time)

(require-builtin helix/core/text)

;; C
(define (evil-change-line)
  (evil-delete-line)
  (helix.static.move_line_up)
  (helix.static.open_below)
  (helix.static.goto_line_start))

(provide 
  evil-change-line
)
