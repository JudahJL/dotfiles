(setq custom-file "~/.emacs.d/.emacs.custom.el")

(let ((local-bin (expand-file-name "~/.local/bin")))
  (add-to-list 'exec-path local-bin)
  (setenv "PATH" (concat local-bin path-separator (getenv "PATH"))))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

(when (< emacs-major-version 27)
  (package-initialize))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package-ensure)
(setq use-package-always-ensure t)
(setq inhibit-startup-screen t)

(tool-bar-mode -1)
(menu-bar-mode -1)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode)
(setq make-backup-files nil)

(use-package pinentry
  :config
  (pinentry-start))

(use-package guru-mode
  :config
  (setq guru-warn-only t)
  (guru-global-mode 1))

(use-package gruber-darker-theme
  :config
  (load-theme 'gruber-darker t))

(when (find-font (font-spec :family "Iosevka NF"))
  (add-to-list 'default-frame-alist '(font . "Iosevka NF-16")))

(use-package nerd-icons
  :custom
  (nerd-icons-font-family "Iosevka NF"))

(use-package ripgrep)

(use-package vertico
  :init
  (vertico-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t))

(use-package marginalia
  :init
  (marginalia-mode))

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;; Example configuration for Consult
(use-package consult
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g r" . consult-grep-match)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)                  ;; Alternative: consult-fd
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  This improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref
   consult-source-bookmark consult-source-file-register
   consult-source-recent-file consult-source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
)

(use-package embark
  :bind
  ( :map global-map
   ("C-." . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  (context-menu-mode 1)
  (add-hook 'context-menu-functions #'embark-context-menu 100)

  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult)

(use-package corfu
  :init
  (global-corfu-mode)

  :custom
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.15)
  (corfu-cycle t))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

(use-package eglot
  :hook
  ((python-ts-mode . eglot-ensure)
   (rust-ts-mode . eglot-ensure)
   (go-ts-mode . eglot-ensure)
   (c-ts-mode . eglot-ensure)
   (c++-ts-mode . eglot-ensure)
   (js-ts-mode . eglot-ensure)
   (typescript-ts-mode . eglot-ensure)
   (tsx-ts-mode . eglot-ensure))

  :custom
  (eglot-autoshutdown t))

(use-package flymake
  :hook (prog-mode . flymake-mode))

(setq major-mode-remap-alist
      '((python-mode . python-ts-mode)
	(js-mode . js-ts-mode)
	(c-mode . c-ts-mode)
	(c++-mode . c++-ts-mode)))

(use-package which-key
  :config
  (which-key-mode 1))

(use-package projectile
  :init
  (setq projectile-project-search-path '("~/projects/"
					 "~/work/"
					 "~/playground/"
					 "~/programming/"))
  :bind
  ( :map global-map
    ("C-c p" . projectile-command-map))
  :config
  (projectile-mode 1))

(use-package dashboard
  :config
  (setq dashboard-projects-backend 'projectile)
  (setq dashboard-items '((recents   . 5)
                          (bookmarks . 5)
                          (projects  . 5)
                          (agenda    . 5)
                          (registers . 5)))
  (setq dashboard-startupify-list '(dashboard-insert-banner
                                    dashboard-insert-banner-title
                                    dashboard-insert-navigator
                                    dashboard-insert-init-info
                                    dashboard-insert-items
                                    dashboard-insert-footer))
  (dashboard-setup-startup-hook))

(use-package multiple-cursors
  :bind
  ( :map global-map
    ("C-S-c C-S-c" . mc/edit-lines)
    ("C->" . mc/mark-next-like-this)
    ("C-<" . mc/mark-previous-like-this)
    ("C-c C-<" . mc/mark-all-like-this)
    ("C-\"" . mc/skip-to-next-like-this)
    ("C-:" . mc/skip-to-previous-like-this)))

(use-package magit
  :custom
  (git-commit-signoff t))

(setq treesit-language-source-alist
      '((c3 "https://github.com/c3lang/tree-sitter-c3")))

(unless (treesit-language-available-p 'c3)
  (treesit-install-language-grammar 'c3))

(use-package c3-ts-mode
  :vc (:url "https://github.com/c3lang/c3-ts-mode"
	    :rev :newest)
  :mode "\\.c3[it]?\\'")

(unless (file-exists-p custom-file)
  (with-temp-buffer
    (write-file custom-file)))

(load custom-file)
