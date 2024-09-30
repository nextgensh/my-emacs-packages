;;; mypackages/my-wttr.el -*- lexical-binding: t; -*-

;;; Commentary:
;;; Just a very simple package that gets weather data and then displays it.
;;; Heavily inspired by the original MELPA package for wttr. I only coded this to teach
;;; myself how to code in emacs lisp.

;;; Code:
(require 'url)

(defvar my/wttr-string "")
(defvar my/wttr-timer nil)

(defun my/wttr-clean-string (str)
  (decode-coding-string
   (string-join
    (string-split str) " ") 'utf-8)
  )

(defun my/wttr-url-callback (status)
  "Callback function for my url"
  (ignore status)
  (with-current-buffer (current-buffer)
    (goto-char (point-min))
    ;; "^$" matches an empty line. re-search-forward sets point at the end of string that matches that expression.
    (re-search-forward "^$")
                                        ;(message "%s -> WTTR: URL Callback has been called" (current-time-string))
    (setq my/wttr-string
          (my/wttr-clean-string
           (buffer-substring (+ 1 (point)) (point-max))))
    )
  )

(defun my/test-and-add-mode-line ()
  "Method which checks if the my/wttr-string symbol is in
  global-mode-string and adds if not"
  (if (memq 'my/wttr-string global-mode-string) ()
    (setq global-mode-string (append global-mode-string '(my/wttr-string))))
  )

(defun my/wttr-generate-url ()
  "Method which generates the url string and returns it"
  (if (< (string-to-number (format-time-string "%H")) 18)
      "https://wttr.in/tucson?u&format=%c %t" "https://wttr.in/tucson?u&format=%m %t")
  )

(defun my/wttr-fetch-url-async (url)
  "Method which can fetch the given url async"
  (url-retrieve url 'my/wttr-url-callback))

(defun my/wttr-start-weather ()
  "Method to start the WTTR weather updating utility"
  (interactive)
  ;; Set up the mode line if needed.
  (my/test-and-add-mode-line)
  (let ((wttr-startuptime 60) ;; In seconds
        (wttr-repeat (* 60 15))) ;; Repeat every 15 mins
    (setq my/wttr-timer
          ;; So we don't overload at the start, will wait for 60 seconds before looking up the weather.
          (run-at-time wttr-startuptime wttr-repeat #'my/wttr-fetch-url-async (my/wttr-generate-url))))
  )

(defun my/wttr-stop-weather ()
  "Method to stop WTTR weather update utility and clear the misc modeline section"
  (interactive)
  (cancel-timer my/wttr-timer)
  (setq global-mode-string (remove 'my/wttr-string global-mode-string))
  )
