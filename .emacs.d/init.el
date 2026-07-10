(setq custom-file "~/.emacs.d/.emacs.custom.el")

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

(when (< emacs-major-version 27)
  (package-initialize))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(use-package nerd-icons
  :ensure t
  :custom
  (nerd-icons-font-family "Iosevka Nerd Font"))

(use-package project
  :ensure t)

(use-package dashboard
  :ensure t
  :config
  (setq dashboard-projects-backend 'project-el)
  (add-to-list 'dashboard-items '(projects . 5) t)
  (dashboard-setup-startup-hook))

(use-package gruber-darker-theme
  :ensure t
  :config
  (load-theme 'gruber-darker t))

(use-package smex
  :ensure t
  :config
  (smex-initialize)
  :bind
  ( :map global-map
   ("M-x" . smex)
   ("M-X" . smex-major-mode-commands)
   ("C-c C-c M-x" . execute-extended-command)))

(use-package multiple-cursors
  :ensure t
  :bind
  ( :map global-map
    ("C-S-c C-S-c" . mc/edit-lines)
    ("C->" . mc/mark-next-like-this)
    ("C-<" . mc/mark-previous-like-this)
    ("C-c C-<" . mc/mark-all-like-this)
    ("C-\"" . mc/skip-to-next-like-this)
    ("C-:" . mc/skip-to-previous-like-this)))

;; TODO: enable signoff and sign commits automatically
(use-package magit)

(when (find-font (font-spec :family "Iosevka"))
  (add-to-list 'default-frame-alist '(font . "Iosevka-16")))


(tool-bar-mode 0)
(menu-bar-mode)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode)
(ido-mode 1)
(ido-everywhere 1)
(setq make-backup-files nil)

(unless (file-exists-p custom-file)
  (with-temp-buffer
    (write-file custom-file)))

(load custom-file)
