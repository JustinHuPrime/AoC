#lang racket

(define (find-links from links)
  (cond [(empty? links) empty]
        [else (if (string=? from (caar links))
                  (cons (cdar links) (find-links from (cdr links)))
                  (find-links from (cdr links)))]))

(define (string-lowercase s)
  (andmap char-lower-case? (string->list s)))

(define (count-paths node links path)
  (cond [(and (string-lowercase node)
              (member node path))
         0]
        [(string=? node "end")
         1]
        [else
         (apply + (map (curryr count-paths links (cons node path)) (find-links node links)))]))

(let ([links (foldr (λ (link rsf)
                      (match-let ([`(,from . ,to) link])
                        (list* link
                               (cons to from)
                               rsf)))
                    empty
                    (map (compose (curry apply cons)
                                  (curryr string-split "-"))
                         (file->lines "12.txt")))])
  (count-paths "start" links empty))