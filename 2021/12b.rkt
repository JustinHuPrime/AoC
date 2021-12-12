#lang racket

(define (find-links from links)
  (cond [(empty? links) empty]
        [else (if (string=? from (caar links))
                  (cons (cdar links) (find-links from (cdr links)))
                  (find-links from (cdr links)))]))

(define (string-lowercase s)
  (andmap char-lower-case? (string->list s)))

(define (cannot-visit? node path)
  (and (string-lowercase node)
       (or (and (check-duplicates path (λ (a b) (and (string-lowercase a) (string-lowercase b) (string=? a b))))
                (member node path))
           (and (string=? node "start")
                (member "start" path))
           (and (string=? node "end")
                (member "end" path)))))

(define (count-paths node links path)
  (cond [(cannot-visit? node path)
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