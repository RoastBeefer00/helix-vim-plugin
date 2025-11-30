(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))

(require "helix/configuration.scm")
(require "helix/keymaps.scm")
(require "helix/editor.scm")
(require "helix/misc.scm")
(require "helix/ext.scm")
(require "helix/components.scm")

(require "change-motions.scm")
(require "delete-motions.scm")
(require "normal-motions.scm")
(require "visual-motions.scm")
(require "yank-motions.scm")
(require "utils.scm")

(define vim-keybindings
  (keymap (normal (l ":move-char-right-same-line")
                  (h ":move-char-left-same-line")
                  (k ":move-line-up")
                  (j ":move-line-down")
                  (f ":evil-find-next-char")
                  (F ":evil-find-prev-char")
                  (t ":evil-find-till-char")
                  (T ":evil-till-prev-char")
                  (a ":evil-append-mode")
                  (w ":evil-next-word-start")
                  (e ":evil-next-word-end")
                  (G ":evil-goto-line-or-last")
                  (A-d "no_op")
                  (A-c "no_op")
                  ;; Selecting the whole file
                  (% "match_brackets")
                  (X "no_op")
                  (A-x "no_op")
                  (p "paste_after")
                  (P "paste_before")
                  ;; TODO: More delete things
                  (d (d ":evil-delete-line") (w ":evil-delete-word"))
                  ;; TODO: More change things
                  (c (c ":evil-change-line"))
                  (x "delete_selection_noyank")
                  ;; TODO: More yank things
                  (y (y ":evil-yank-line") 
                     ;; TODO: around/inner long word
                     ;; TODO: paragraph, function, comment, test, html tag, etc.
                     (a (w ":yank-around-word")) 
                     (i (w ":yank-inner-word"))
                     (w ":yank-word")
                     (W ":yank-long-word")
                     (e ":yank-word")
                     (E ":yank-long-word")
                     (b ":yank-prev-word")
                     (B ":yank-prev-long-word")
                     ($ ":yank-line-end")
                     ("0" ":yank-line-start")
                     (^ ":yank-line-start-non-whitespace")
                  )
                  (b ":evil-prev-word-start")
                  (B ":evil-prev-long-word-start")
                  (E ":evil-next-long-word-end")
                  (W ":evil-next-long-word-start")
                  ("0" "goto_line_start")
                  ($ "goto_line_end")
                  (^ "goto_first_nonwhitespace")
                  (del "delete_selection"))
          ;; Select bindings
          ;; TODO: Rename this to VIS
          (select (a "select_textobject_around")
                  (i "select_textobject_inner")
                  (h ":extend-char-left-same-line")
                  (l ":extend-char-right-same-line")
                  (j ":extend-line-down")
                  (k ":extend-line-up"))
          (insert (C-d "unindent") (C-t "indent"))))

(define (set-vim-keybindings!)
  (add-global-keybinding vim-keybindings))

(provide set-vim-keybindings!)
(provide move-char-right-same-line
         move-char-left-same-line
         move-line-up
         move-line-down
         evil-goto-line-or-last
         evil-find-next-char
         evil-find-prev-char
         evil-find-till-char
         evil-till-prev-char
         evil-append-mode
         evil-next-word-start
         evil-next-word-end
         evil-delete-line
         evil-delete-word
         evil-change-line
         evil-yank-line
         yank-around-word
         yank-inner-word
         evil-prev-word-start
         evil-prev-long-word-start
         evil-next-long-word-end
         evil-next-long-word-start
         extend-char-left-same-line
         extend-char-right-same-line
         extend-line-down
         extend-line-up
         yank-word
         yank-long-word
         yank-prev-word
         yank-prev-long-word
         yank-line-start
         yank-line-end
         yank-line-start-non-whitespace
         )
