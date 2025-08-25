;; FitnessChain: Fitness Training and Achievement Reward System
;; Version: 1.0.0

;; Constants
(define-constant GYM_CAPACITY u3600000)
(define-constant BASE_WORKOUT_REWARD u40)
(define-constant FITNESS_BONUS u20)
(define-constant MAX_ATHLETE_LEVEL u25)
(define-constant ERR_INVALID_FITNESS_ACTIVITY u1)
(define-constant ERR_NO_FITNESS_TOKENS u2)
(define-constant ERR_GYM_CAPACITY_EXCEEDED u3)
(define-constant BLOCKS_PER_FITNESS_CYCLE u2592)
(define-constant RECOVERY_MULTIPLIER u12)
(define-constant MIN_RECOVERY_PERIOD u1296)
(define-constant OVERTRAINING_PENALTY u35)

;; Data Variables
(define-data-var total-fitness-tokens-distributed uint u0)
(define-data-var total-fitness-activities uint u0)
(define-data-var gym-trainer principal tx-sender)

;; Data Maps
(define-map athlete-activities principal uint)
(define-map athlete-fitness-tokens principal uint)
(define-map workout-session-start-time principal uint)
(define-map athlete-fitness-level principal uint)
(define-map athlete-last-activity principal uint)
(define-map athlete-recovery-period principal uint)
(define-map athlete-recovery-start-block principal uint)
(define-map workout-intensity principal uint)
(define-map athlete-achievement-count principal uint)
(define-map strength-progression principal uint)

;; Public Functions
(define-public (start-workout-session (exercise-type uint) (intensity-level uint))
  (let
    (
      (athlete tx-sender)
    )
    (asserts! (and (> exercise-type u0) (> intensity-level u0) (<= intensity-level u10)) (err ERR_INVALID_FITNESS_ACTIVITY))
    (map-set workout-session-start-time athlete burn-block-height)
    (map-set workout-intensity athlete intensity-level)
    (ok true)
  ))

(define-public (complete-workout-session (exercise-type uint) (performance-score uint))
  (let
    (
      (athlete tx-sender)
      (start-block (default-to u0 (map-get? workout-session-start-time athlete)))
      (blocks-working-out (- burn-block-height start-block))
      (last-activity-block (default-to u0 (map-get? athlete-last-activity athlete)))
      (fitness-level (default-to u0 (map-get? athlete-fitness-level athlete)))
      (capped-fitness (if (<= fitness-level MAX_ATHLETE_LEVEL) fitness-level MAX_ATHLETE_LEVEL))
      (performance-bonus (/ (* performance-score u12) u100))
      (strength-bonus (default-to u0 (map-get? strength-progression athlete)))
      (workout-reward (+ BASE_WORKOUT_REWARD (* capped-fitness FITNESS_BONUS) performance-bonus strength-bonus))
    )
    (asserts! (and (> start-block u0) (>= blocks-working-out exercise-type) (<= performance-score u100)) (err ERR_INVALID_FITNESS_ACTIVITY))
    
    (map-set athlete-activities athlete (+ (default-to u0 (map-get? athlete-activities athlete)) u1))
    (map-set athlete-fitness-tokens athlete (+ (default-to u0 (map-get? athlete-fitness-tokens athlete)) workout-reward))
    
    (if (< (- burn-block-height last-activity-block) BLOCKS_PER_FITNESS_CYCLE)
      (map-set athlete-fitness-level athlete (+ fitness-level u1))
      (map-set athlete-fitness-level athlete u1)
    )
    
    (if (>= performance-score u85)
      (map-set strength-progression athlete (+ strength-bonus u8))
      true
    )
    
    (map-set athlete-last-activity athlete burn-block-height)
    (var-set total-fitness-activities (+ (var-get total-fitness-activities) u1))
    (var-set total-fitness-tokens-distributed (+ (var-get total-fitness-tokens-distributed) workout-reward))
    
    (asserts! (<= (var-get total-fitness-tokens-distributed) GYM_CAPACITY) (err ERR_GYM_CAPACITY_EXCEEDED))
    (ok workout-reward)
  ))

(define-public (claim-fitness-rewards)
  (let
    (
      (athlete tx-sender)
      (token-balance (default-to u0 (map-get? athlete-fitness-tokens athlete)))
    )
    (asserts! (> token-balance u0) (err ERR_NO_FITNESS_TOKENS))
    (map-set athlete-fitness-tokens athlete u0)
    (ok token-balance)
  ))

;; Recovery Features
(define-public (start-recovery-period (recovery-intensity uint))
  (let
    (
      (athlete tx-sender)
    )
    (asserts! (> recovery-intensity u0) (err ERR_INVALID_FITNESS_ACTIVITY))
    (asserts! (>= (var-get total-fitness-tokens-distributed) recovery-intensity) (err ERR_GYM_CAPACITY_EXCEEDED))
    
    (map-set athlete-recovery-period athlete recovery-intensity)
    (map-set athlete-recovery-start-block athlete burn-block-height)
    (var-set total-fitness-tokens-distributed (- (var-get total-fitness-tokens-distributed) recovery-intensity))
    (ok recovery-intensity)
  ))

(define-public (complete-recovery-period)
  (let
    (
      (athlete tx-sender)
      (recovery-amount (default-to u0 (map-get? athlete-recovery-period athlete)))
      (recovery-start-block (default-to u0 (map-get? athlete-recovery-start-block athlete)))
      (blocks-recovering (- burn-block-height recovery-start-block))
      (penalty (if (< blocks-recovering MIN_RECOVERY_PERIOD) (/ (* recovery-amount OVERTRAINING_PENALTY) u100) u0))
      (recovery-bonus (if (>= blocks-recovering MIN_RECOVERY_PERIOD) (/ (* recovery-amount RECOVERY_MULTIPLIER) u100) u0))
      (final-amount (+ (- recovery-amount penalty) recovery-bonus))
    )
    (asserts! (> recovery-amount u0) (err ERR_NO_FITNESS_TOKENS))
    
    (map-set athlete-recovery-period athlete u0)
    (map-set athlete-recovery-start-block athlete u0)
    (var-set total-fitness-tokens-distributed (+ (var-get total-fitness-tokens-distributed) final-amount))
    (ok final-amount)
  ))

(define-public (achieve-fitness-milestone (milestone-type uint) (difficulty-rating uint))
  (let
    (
      (athlete tx-sender)
      (fitness-level (default-to u0 (map-get? athlete-fitness-level athlete)))
      (achievement-count (default-to u0 (map-get? athlete-achievement-count athlete)))
      (milestone-bonus (+ (* milestone-type u30) (* achievement-count u10)))
    )
    (asserts! (and (> milestone-type u0) (> difficulty-rating u0) (>= fitness-level u8)) (err ERR_INVALID_FITNESS_ACTIVITY))
    
    (map-set athlete-fitness-tokens athlete (+ (default-to u0 (map-get? athlete-fitness-tokens athlete)) milestone-bonus))
    (map-set athlete-achievement-count athlete (+ achievement-count u1))
    (var-set total-fitness-tokens-distributed (+ (var-get total-fitness-tokens-distributed) milestone-bonus))
    
    (ok milestone-bonus)
  ))

(define-public (participate-in-challenge (challenge-type uint) (team-size uint))
  (let
    (
      (athlete tx-sender)
      (fitness-level (default-to u0 (map-get? athlete-fitness-level athlete)))
      (strength-level (default-to u0 (map-get? strength-progression athlete)))
      (challenge-bonus (+ (* challenge-type u25) (* team-size u15) (* strength-level u3)))
    )
    (asserts! (and (> challenge-type u0) (>= fitness-level u10)) (err ERR_INVALID_FITNESS_ACTIVITY))
    
    (map-set athlete-fitness-tokens athlete (+ (default-to u0 (map-get? athlete-fitness-tokens athlete)) challenge-bonus))
    (var-set total-fitness-tokens-distributed (+ (var-get total-fitness-tokens-distributed) challenge-bonus))
    
    (ok challenge-bonus)
  ))

;; Read-Only Functions
(define-read-only (get-fitness-activity-count (user principal))
  (default-to u0 (map-get? athlete-activities user)))

(define-read-only (get-fitness-token-balance (user principal))
  (default-to u0 (map-get? athlete-fitness-tokens user)))

(define-read-only (get-fitness-level (user principal))
  (default-to u0 (map-get? athlete-fitness-level user)))

(define-read-only (get-achievement-count (user principal))
  (default-to u0 (map-get? athlete-achievement-count user)))

(define-read-only (get-recovery-period (user principal))
  (default-to u0 (map-get? athlete-recovery-period user)))

(define-read-only (get-strength-progression (user principal))
  (default-to u0 (map-get? strength-progression user)))

(define-read-only (get-gym-stats)
  {
    total-fitness-activities: (var-get total-fitness-activities),
    total-fitness-tokens-distributed: (var-get total-fitness-tokens-distributed),
    gym-capacity: GYM_CAPACITY
  })

(define-read-only (calculate-workout-reward (fitness-level uint) (performance-score uint) (strength-bonus uint))
  (let
    (
      (capped-fitness (if (<= fitness-level MAX_ATHLETE_LEVEL) fitness-level MAX_ATHLETE_LEVEL))
      (performance-bonus (/ (* performance-score u12) u100))
    )
    (+ BASE_WORKOUT_REWARD (* capped-fitness FITNESS_BONUS) performance-bonus strength-bonus)
  ))

;; Private Functions
(define-private (is-gym-trainer)
  (is-eq tx-sender (var-get gym-trainer)))

(define-private (validate-fitness-parameters (exercise-type uint) (performance-score uint))
  (and (> exercise-type u0) (<= performance-score u100)))