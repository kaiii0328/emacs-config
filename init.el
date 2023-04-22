;;; init.el --- Load the full configuration -*- lexical-binding: t -*-
;;; Commentary:

;; This file bootstraps the configuration, which is divided into
;; a number of other files.

;;; Code:

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(eval-when-compile
  (require 'use-package))

(load-theme 'solarized-dark t)

(let ((minver "25.1"))
  (when (version< emacs-version minver)
    (error "Your Emacs is too old -- this config requires v%s or higher" minver)))
(when (version< emacs-version "26.1")
  (message "Your Emacs is old, and some functionality in this config will be disabled. Please upgrade if possible."))

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory)) ; 设定源码加载路径
;; (require 'init-benchmarking) ;; Measure startup time

(defconst *spell-check-support-enabled* nil) ;; Enable with t if you prefer
(defconst *is-a-mac* (eq system-type 'darwin))

;; Adjust garbage collection thresholds during startup, and thereafter

(let ((normal-gc-cons-threshold (* 20 1024 1024))
      (init-gc-cons-threshold (* 128 1024 1024)))
  (setq gc-cons-threshold init-gc-cons-threshold)
  (add-hook 'emacs-startup-hook
            (lambda () (setq gc-cons-threshold normal-gc-cons-threshold))))

(electric-pair-mode t)                       ; 自动补全括号
(add-hook 'prog-mode-hook #'show-paren-mode) ; 编程模式下，光标在括号上时高亮另一个括号
(column-number-mode t)                       ; 在 Mode line 上显示列号
(global-auto-revert-mode t)                  ; 当另一程序修改了文件时，让 Emacs 及时刷新 Buffer
(delete-selection-mode t)                    ; 选中文本后输入文本会替换文本（更符合我们习惯了的其它编辑器的逻辑）
(setq inhibit-startup-message t)             ; 关闭启动 Emacs 时的欢迎界面
(setq make-backup-files nil)                 ; 关闭文件自动备份
(setq auto-save-default nil)                 ; close auto save
(add-hook 'prog-mode-hook #'hs-minor-mode)   ; 编程模式下，可以折叠代码块
(global-display-line-numbers-mode 1)         ; 在 Window 显示行号
(tool-bar-mode -1)                           ; 关闭 Tool bar
(menu-bar-mode 0)
;;(when (display-graphic-p) (toggle-scroll-bar -1)) ; 图形界面时关闭滚动条

(savehist-mode 1)                            ; （可选）打开 Buffer 历史记录保存
(setq display-line-numbers-type 'relative)   ; （可选）显示相对行号
(add-to-list 'default-frame-alist '(width . 150))  ; （可选）设定启动图形界面时的初始 Frame 宽度（字符数）
(add-to-list 'default-frame-alist '(height . 55)) ; （可选）设定启动图形界面时的初始 Frame 高度（字符数）

(global-set-key (kbd "C-c '") 'comment-or-uncomment-region) ; 为选中的代码加注释/去注释
(global-set-key (kbd "RET") 'newline-and-indent) ; new line and indent
(global-set-key (kbd "M-w") 'kill-region)              ; 交换 M-w 和 C-w，M-w 为剪切
(global-set-key (kbd "C-w") 'kill-ring-save)           ; 交换 M-w 和 C-w，C-w 为复制
(global-set-key (kbd "C-a") 'back-to-indentation)      ; 交换 C-a 和 M-m，C-a 为到缩进后的行首
(global-set-key (kbd "M-m") 'move-beginning-of-line)   ; 交换 C-a 和 M-m，M-m 为到真正的行首
(global-set-key (kbd "C-j") nil)
;; 删去光标所在行（在图形界面时可以用 "C-S-<DEL>"，终端常会拦截这个按法)
(global-set-key (kbd "C-j C-k") 'kill-whole-line)


(use-package counsel
  :ensure t)

(use-package ivy
  :ensure t
  :init
  (ivy-mode 1)
  (counsel-mode 1)
  :config
  (setq ivy-use-virtual-buffers t)
  (setq search-default-mode #'char-fold-to-regexp)
  (setq ivy-count-format "(%d/%d) ")
  :bind
  (("C-s" . 'swiper)
   ("C-x b" . 'ivy-switch-buffer)
   ("C-c v" . 'ivy-push-view)
   ("C-c s" . 'ivy-switch-view)
   ("C-c V" . 'ivy-pop-view)
   ("C-x C-@" . 'counsel-mark-ring); 在某些终端上 C-x C-SPC 会被映射为 C-x C-@，比如在 macOS 上，所以要手动设置
   ("C-x C-SPC" . 'counsel-mark-ring)
   :map minibuffer-local-map
   ("C-r" . counsel-minibuffer-history)))

(use-package flycheck
  :ensure t
  :config
  (setq truncate-lines nil) ; 如果单行信息很长会自动换行
  :hook                   ; 为模式设置 hoo
  (prog-mode . flycheck-mode))

(use-package ace-window
  :ensure t
  :bind (("C-x o" . 'ace-window)))

(use-package mwim
  :ensure t
  :bind
  ("C-a" . mwim-beginning-of-code-or-line)
  ("C-e" . mwim-end-of-code-or-line))

(use-package avy
  :ensure t
  :bind
  (("M-j" . avy-goto-char-timer)))


(use-package hydra
  :ensure t)

(use-package use-package-hydra
  :ensure t)

;; Prevent undo tree files from polluting your git repo
(setq undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))
(use-package undo-tree
  :ensure t
  :init (global-undo-tree-mode)
  :after hydra
  :bind ("C-x C-h u" . hydra-undo-tree/body)
  :hydra (hydra-undo-tree (:hint nil)
  "
  _p_: undo  _n_: redo _s_: save _l_: load   "
  ("p"   undo-tree-undo)
  ("n"   undo-tree-redo)
  ("s"   undo-tree-save-history)
  ("l"   undo-tree-load-history)
  ("u"   undo-tree-visualize "visualize" :color blue)
  ("q"   nil "quit" :color blue)))

(use-package multiple-cursors
  :ensure t
  :after hydra
  :bind
  (("C-x C-h m" . hydra-multiple-cursors/body)
   ("C-S-<mouse-1>" . mc/toggle-cursor-on-click))
  :hydra (hydra-multiple-cursors
		  (:hint nil)
		  "
Up^^             Down^^           Miscellaneous           % 2(mc/num-cursors) cursor%s(if (> (mc/num-cursors) 1) \"s\" \"\")
------------------------------------------------------------------
 [_p_]   Prev     [_n_]   Next     [_l_] Edit lines  [_0_] Insert numbers
 [_P_]   Skip     [_N_]   Skip     [_a_] Mark all    [_A_] Insert letters
 [_M-p_] Unmark   [_M-n_] Unmark   [_s_] Search      [_q_] Quit
 [_|_] Align with input CHAR       [Click] Cursor at point"
		  ("l" mc/edit-lines :exit t)
		  ("a" mc/mark-all-like-this :exit t)
		  ("n" mc/mark-next-like-this)
		  ("N" mc/skip-to-next-like-this)
		  ("M-n" mc/unmark-next-like-this)
		  ("p" mc/mark-previous-like-this)
		  ("P" mc/skip-to-previous-like-this)
		  ("M-p" mc/unmark-previous-like-this)
		  ("|" mc/vertical-align)
		  ("s" mc/mark-all-in-region-regexp :exit t)
		  ("0" mc/insert-numbers :exit t)
		  ("A" mc/insert-letters :exit t)
		  ("<mouse-1>" mc/add-cursor-on-click)
		  ;; Help with click recognition in this hydra
		  ("<down-mouse-1>" ignore)
		  ("<drag-mouse-1>" ignore)
		  ("q" nil)))

 (use-package dashboard
  :ensure t
  :config
  (setq dashboard-banner-logo-title "Welcome Wangkai!") ;; 个性签名，随读者喜好设置
  (setq dashboard-projects-backend 'projectile) ;; 读者可以暂时注释掉这一行，等安装了 projectile 后再使用
  (setq dashboard-startup-banner 'official) ;; 也可以自定义图片
  (setq dashboard-items '((recents  . 5)   ;; 显示多少个最近文件
			  (bookmarks . 5)  ;; 显示多少个最近书签
			  (projects . 10))) ;; 显示多少个最近项目
  (dashboard-setup-startup-hook))

(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

;; auto complete
(use-package company
  :ensure t
  :init (global-company-mode)
  :config
  (setq company-minimum-prefix-length 1) ; 只需敲 1 个字母就开始进行自动补全
  (setq company-tooltip-align-annotations t)
  (setq company-idle-delay 0.0)
  (setq company-show-numbers t) ;; 给选项编号 (按快捷键 M-1、M-2 等等来进行选择).
  (setq company-selection-wrap-around t)
  (setq company-transformers '(company-sort-by-occurrence))) ; 根据选择的频率进行排序，读者如果不喜欢可以去掉

(use-package yasnippet
  :ensure t
  :hook
  (prog-mode . yas-minor-mode)
  :config
  (yas-reload-all)
  ;; add company-yasnippet to company-backends
  (defun company-mode/backend-with-yas (backend)
    (if (and (listp backend) (member 'company-yasnippet backend))
	backend
      (append (if (consp backend) backend (list backend))
              '(:with company-yasnippet))))
  (setq company-backends (mapcar #'company-mode/backend-with-yas company-backends))
  ;; unbind <TAB> completion
  (define-key yas-minor-mode-map [(tab)]        nil)
  (define-key yas-minor-mode-map (kbd "TAB")    nil)
  (define-key yas-minor-mode-map (kbd "<tab>")  nil)
  :bind
  (:map yas-minor-mode-map ("<backtab>" . yas-expand)))

(use-package yasnippet-snippets
  :ensure t
  :after yasnippet)


(use-package lsp-mode
  :ensure t
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c l"
	lsp-file-watch-threshold 500)
  :hook 
  (lsp-mode . lsp-enable-which-key-integration) ; which-key integration
  :commands (lsp lsp-deferred)
  :config
  (setq lsp-completion-provider :none) ; 阻止 lsp 重新设置 company-backend 而覆盖我们 yasnippet 的设置
  (setq lsp-headerline-breadcrumb-enable t)
  :bind
  ("C-c l s" . lsp-ivy-workspace-symbol)) ; 可快速搜索工作区内的符号（类名、函数名、变量名等）

(use-package lsp-ivy
  :ensure t
  :after (lsp-mode))

(use-package projectile
  :ensure t
  :bind (("C-c p" . projectile-command-map))
  :config
  (setq projectile-mode-line "Projectile")
  (setq projectile-track-known-projects-automatically nil))

(use-package counsel-projectile
  :ensure t
  :after (projectile)
  :init (counsel-projectile-mode))

(use-package magit
  :ensure t)


(provide 'init)


;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (good-scroll evil vterm-toggle lsp-ivy lsp-mode company yasnippet-snippets multiple-cursors hydra use-package-hydra undo-tree solarized-theme smart-mode-line use-package sml-mode))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
