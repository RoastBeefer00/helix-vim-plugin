(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))

(require "delete-motions.scm")

(require-builtin steel/time)

(require-builtin helix/core/text)

(require "vim/visual-motions.scm")

(define (change-impl func)
  (func)
  (helix.static.change_selection))

;; S
(define (evil-change-line)
  (change-impl helix.static.extend_to_line_bounds))

;; cw
(define (evil-change-word)
  (change-impl helix.static.extend_next_word_end))

;; cW
(define (evil-change-long-word)
  (change-impl helix.static.extend_next_long_word_end))

;; cb
(define (evil-change-prev-word)
  (change-impl helix.static.extend_prev_word_start))

;; cB
(define (evil-change-prev-long-word)
  (change-impl helix.static.extend_prev_long_word_start))

;; ce
(define (evil-change-word-end)
  (change-impl helix.static.extend_next_word_end))

;; cE
(define (evil-change-long-word-end)
  (change-impl helix.static.extend_next_long_word_end))

;; caw
(define (evil-change-around-word)
  (change-impl select-around-word))

;; ciw
(define (evil-change-inner-word)
  (change-impl select-inner-word))

;; caW
;; (define (evil-change-around-long-word)
;;   (select-around-word)
;;   (helix.static.change_selection))

;; ciW
;; (define (evil-change-inner-long-word)
;;   (select-inner-word)
;;   (helix.static.change_selection))

;; cap
(define (evil-change-around-paragraph)
  (change-impl select-around-paragraph))

;; cip
(define (evil-change-inner-paragraph)
  (change-impl select-inner-paragraph))

;; caf
(define (evil-change-around-function)
  (change-impl select-around-function))

;; cif
(define (evil-change-inner-function)
  (change-impl select-inner-function))

;; cac
(define (evil-change-around-comment)
  (change-impl select-around-comment))

;; cic
(define (evil-change-inner-comment)
  (change-impl select-inner-comment))

;; cae
(define (evil-change-around-data-structure)
  (change-impl select-around-data-structure))

;; cie
(define (evil-change-inner-data-structure)
  (change-impl select-inner-data-structure))

;; cax
(define (evil-change-around-html-tag)
  (change-impl select-around-html-tag))

;; cix
(define (evil-change-inner-html-tag)
  (change-impl select-inner-html-tag))

;; cat
(define (evil-change-around-type-definition)
  (change-impl select-around-type-definition))

;; cit
(define (evil-change-inner-type-definition)
  (change-impl select-inner-type-definition))

;; caT
(define (evil-change-around-test)
  (change-impl select-around-test))

;; ciT
(define (evil-change-inner-test)
  (change-impl select-inner-test))

;; ca{
(define (evil-change-around-curly)
  (change-impl select-around-curly))

;; ci{
(define (evil-change-inner-curly)
  (change-impl select-inner-curly))

;; ca[
(define (evil-change-around-square)
  (change-impl select-around-square))

;; ci[
(define (evil-change-inner-square)
  (change-impl select-inner-square))

;; ci(
(define (evil-change-inner-paren)
  (change-impl select-inner-paren))

;; ca(
(define (evil-change-around-paren)
  (change-impl select-around-paren))

;; ca"
(define (evil-change-around-double-quote)
  (change-impl select-around-double-quote))

;; ci"
(define (evil-change-inner-double-quote)
  (change-impl select-inner-double-quote))

;; ca'
(define (evil-change-around-single-quote)
  (change-impl select-around-single-quote))

;; ci'
(define (evil-change-inner-single-quote)
  (change-impl select-inner-single-quote))

;; ca<
(define (evil-change-around-arrow)
  (change-impl select-around-arrow))

;; ci<
(define (evil-change-inner-arrow)
  (change-impl select-inner-arrow))

(provide 
  evil-change-line
  evil-change-word
  evil-change-long-word
  evil-change-prev-word
  evil-change-prev-long-word
  evil-change-word-end
  evil-change-long-word-end
  evil-change-around-word
  evil-change-inner-word
  evil-change-around-paragraph
  evil-change-inner-paragraph
  evil-change-around-function
  evil-change-inner-function
  evil-change-around-comment
  evil-change-inner-comment
  evil-change-around-data-structure
  evil-change-inner-data-structure
  evil-change-around-html-tag
  evil-change-inner-html-tag
  evil-change-around-type-definition
  evil-change-inner-type-definition
  evil-change-around-test
  evil-change-inner-test
  evil-change-around-curly
  evil-change-inner-curly
  evil-change-around-square
  evil-change-inner-square
  evil-change-inner-paren
  evil-change-around-paren
  evil-change-around-double-quote
  evil-change-inner-double-quote
  evil-change-around-single-quote
  evil-change-inner-single-quote
  evil-change-around-arrow
  evil-change-inner-arrow
  evil-change-inner-square
  evil-change-inner-paren
  evil-change-around-paren
  evil-change-around-double-quote
  evil-change-inner-double-quote
  evil-change-around-single-quote
  evil-change-inner-single-quote
  evil-change-around-arrow
  evil-change-inner-arrow
)
