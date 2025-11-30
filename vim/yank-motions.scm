(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))

(require "utils.scm")
(require "visual-motions.scm")
(require "helix/misc.scm")

(require-builtin steel/time)

(require-builtin helix/core/text)

(define (yank-impl func)
  (func)
  (helix.static.yank_main_selection_to_clipboard)
  (helix.static.flip_selections)
  (helix.static.collapse_selection))

;; yaw
(define (yank-around-word)
  (yank-impl select-around-word))

;; yiw
(define (yank-inner-word)
  (yank-impl select-inner-word))

;; yw
(define (yank-word)
  (yank-impl helix.static.extend_next_word_end))

;; yW
(define (yank-long-word)
  (yank-impl helix.static.extend_next_long_word_end))

;; yb
(define (yank-prev-word)
  (yank-impl helix.static.extend_prev_word_start))

;; yB
(define (yank-prev-long-word)
  (yank-impl helix.static.extend_prev_long_word_start))

;; y$
(define (yank-line-end)
  (yank-impl helix.static.extend_to_line_end))

;; y^
(define (yank-line-start)
  (yank-impl helix.static.extend_to_line_start))

;; y0
(define (yank-line-start-non-whitespace)
  (yank-impl helix.static.extend_to_first_nonwhitespace))

;; yy
(define (evil-yank-line)
  (define start-pos (cursor-position))
  (helix.static.extend_to_line_bounds)
  (helix.static.yank_main_selection_to_clipboard)

    ;; Flash the selection briefly (if highlight_selections exists)
  ;; This provides visual feedback
  ;; (when (defined? 'helix.static.highlight_selections)
  ;;   (helix.static.highlight_selections))
  
  (helix.static.normal_mode)
  (helix.static.collapse_selection)
  
  (define current-pos (cursor-position))
  (define distance (- start-pos current-pos))
  (cond
    [(> distance 0) (move-right-n distance)]
    [(< distance 0) (move-left-n (- distance))]))

(provide
  yank-around-word
  yank-inner-word
  yank-word
  yank-long-word
  yank-prev-word
  yank-prev-long-word
  yank-line-end
  yank-line-start
  yank-line-start-non-whitespace
  evil-yank-line
)
