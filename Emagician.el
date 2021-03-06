
(add-to-list 'load-path emagician-dir)
(setq custom-file (concat emagician-dir "custom.el"))

(require 'cl)
(require 'saveplace)
(require 'ffap)
(require 'uniquify)
(require 'ansi-color)
(require 'recentf)

(setq package-user-dir (concat emagician-dir "elpa"))

(setq package-archives
      '(("gnu"         . "http://elpa.gnu.org/packages/")
        ("melpa"       . "http://melpa.milkbox.net/packages/")))

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(defun emagician-starter-kit-load (file &optional header-or-tag)
  "Load configuration from other .org files.
If the optional argument is the id of a subtree then only
configuration from within that subtree will be loaded.  If it is
not an id then it will be interpreted as a tag, and only subtrees
marked with the given tag will be loaded.

For example, to load all of lisp.org simply
add (emagician-starter-kit-load \"lisp\") to your configuration.

To load only the 'window-system' config from
emagician-starter-kit-misc-recommended.org add
 (emagican-starter-kit-load \"misc-recommended\" \"window-system\")
to your configuration."
  (let ((file (expand-file-name (if (string-match ".+\.org" file)
                                    file
                                  (format "%s.org" file))
                                emagician-dir)))
    (org-babel-load-file
     (if header-or-tag
         (let* ((base (file-name-nondirectory file))
                (dir  (file-name-directory file))
                (partial-file (expand-file-name
                               (concat "." (file-name-sans-extension base)
                                       ".part." header-or-tag ".org")
                               dir)))
           (unless (file-exists-p partial-file)
             (with-temp-file partial-file
               (insert
                (with-temp-buffer
                  (insert-file-contents file)
                  (save-excursion
                    (condition-case nil ;; collect as a header
                        (progn
                          (org-link-search (concat"#"header-or-tag))
                          (org-narrow-to-subtree)
                          (buffer-string))
                      (error ;; collect all entries with as tags
                       (let (body)
                         (org-map-entries
                          (lambda ()
                            (save-restriction
                              (org-narrow-to-subtree)
                              (setq body (concat body "\n" (buffer-string)))))
                          header-or-tag)
                         body))))))))
           partial-file)
       file))))

(when nil
  (flet ((sk-load (base)
           (let* ((path          (expand-file-name base emagician-dir))
                  (literate      (concat path ".org"))
                  (encrypted-org (concat path ".org.gpg"))
                  (plain         (concat path ".el"))
                  (encrypted-el  (concat path ".el.gpg")))
             (cond
              ((file-exists-p encrypted-org) (org-babel-load-file encrypted-org))
              ((file-exists-p encrypted-el)  (load encrypted-el))
              ((file-exists-p literate)      (org-babel-load-file literate))
              ((file-exists-p plain)         (load plain)))))
         (remove-extension (name)
           (string-match "\\(.*?\\)\.\\(org\\(\\.el\\)?\\|el\\)\\(\\.gpg\\)?$" name)
           (match-string 1 name)))
    (let ((elisp-dir (expand-file-name "src" emagician-dir))
          (user-dir (expand-file-name user-login-name emagician-dir)))
      ;; add the src directory to the load path
      (add-to-list 'load-path elisp-dir)
      ;; load specific files
      (when (file-exists-p elisp-dir)
        (let ((default-directory elisp-dir))
          (normal-top-level-add-subdirs-to-load-path)))
      ;; load system-specific config
      (sk-load system-name)
      ;; load user-specific config
      (sk-load user-login-name)
      ;; load any files in the user's directory
      (when (file-exists-p user-dir)
        (add-to-list 'load-path user-dir)
        (mapc #'sk-load
              (remove-duplicates
               (mapcar #'remove-extension
                       (directory-files user-dir t ".*\.\\(org\\|el\\)\\(\\.gpg\\)?$"))
               :test #'string=)))))
)

(load custom-file 'noerror)

(defmacro emagician-minor-in-major-mode (major-mode minor-mode)
    (let ((turn-on-symbol (intern (concat "turn-on-" (symbol-name minor-mode)))))
      (list
       'progn 
       (when (not (fboundp turn-on-symbol))
         `(defun ,turn-on-symbol ()
            "Automagickally generated by emagicians starter kit."
            (,minor-mode +1)))
       `(add-hook ,major-mode ,minor-mode))))

(ert-deftest emagician-test-minor-in-major-mode ()
  "emagician-minor-in-major macro test"
  (should (equal (macroexpand '(emagician-minor-in-major-mode elisp-mode paredit-mode))
                 '(progn (defun turn-on-paredit-mode "Automagickally generated by emagicians starter kit." (paredit-mode +1))
                         (add-hook elisp-mode paredit-mode)))))

(defun emagician-expect-package (package)
  "If the named PACKAGE isn't currently installed, install it"
  (unless (package-installed-p package)
    (package-install package)))

(defvar programming-modes '() 
  "A list of modes that are development related, and should all behave the same.")

(defvar programming-mode-hooks '() 
  "A list of hooks to run in every programming mode")

(defun run-programming-mode-hooks ()
  "helper function to execute programming mode hooks."
  (run-hooks 'programming-mode-hooks))



(emagician-starter-kit-load (concat emagician-dir "Emagician-Jonnay"))
