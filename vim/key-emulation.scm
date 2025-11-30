(require (prefix-in helix. "helix/commands.scm"))
(require "helix/editor.scm")
(require "helix/misc.scm")
(require "helix/ext.scm")
(require "helix/components.scm")
(require-builtin helix/core/text)

(define w-key (string->key-event "w"))

(provide 
  w-key
)
