;;; Prints "system-name dep ..." for every defsystem in the file named by $ASD_FILE.

(require :asdf)

(defun dep-name (dep)
  (typecase dep
    (string dep)
    (symbol (symbol-name dep))
    (cons (when (eq (car dep) :version)
            (dep-name (second dep))))))

(defun print-system (form)
  (let ((name (string-downcase (string (second form))))
        (deps (remove nil (mapcar #'dep-name (getf (cddr form) :depends-on)))))
    (format t "~a~{ ~a~}~%" name (mapcar #'string-downcase deps))))

(handler-case
    (let ((*read-eval* nil)
          (*package* (find-package :asdf-user)))
      (with-open-file (in (uiop:getenv "ASD_FILE"))
        (loop for form = (read in nil :eof)
              until (eq form :eof)
              when (and (consp form)
                        (symbolp (car form))
                        (string= (symbol-name (car form)) "DEFSYSTEM"))
                do (print-system form))))
  (error (e)
    (format *error-output* "~a: ~a~%" (uiop:getenv "ASD_FILE") e)
    (uiop:quit 1)))
