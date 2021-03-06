From iris.base_logic Require Export upred.
From iris.algebra Require Export updates.
Local Hint Extern 1 (_ ≼ _) => etrans; [eassumption|].
Local Hint Extern 1 (_ ≼ _) => etrans; [|eassumption].
Local Hint Extern 10 (_ ≤ _) => omega.

(** logical connectives *)
Program Definition uPred_pure_def {M} (φ : Prop) : uPred M :=
  {| uPred_holds n x := φ |}.
Solve Obligations with done.
Definition uPred_pure_aux : { x | x = @uPred_pure_def }. by eexists. Qed.
Definition uPred_pure {M} := proj1_sig uPred_pure_aux M.
Definition uPred_pure_eq :
  @uPred_pure = @uPred_pure_def := proj2_sig uPred_pure_aux.

Instance uPred_inhabited M : Inhabited (uPred M) := populate (uPred_pure True).

Program Definition uPred_and_def {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := P n x ∧ Q n x |}.
Solve Obligations with naive_solver eauto 2 with uPred_def.
Definition uPred_and_aux : { x | x = @uPred_and_def }. by eexists. Qed.
Definition uPred_and {M} := proj1_sig uPred_and_aux M.
Definition uPred_and_eq: @uPred_and = @uPred_and_def := proj2_sig uPred_and_aux.

Program Definition uPred_or_def {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := P n x ∨ Q n x |}.
Solve Obligations with naive_solver eauto 2 with uPred_def.
Definition uPred_or_aux : { x | x = @uPred_or_def }. by eexists. Qed.
Definition uPred_or {M} := proj1_sig uPred_or_aux M.
Definition uPred_or_eq: @uPred_or = @uPred_or_def := proj2_sig uPred_or_aux.

Program Definition uPred_impl_def {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∀ n' x',
       x ≼ x' → n' ≤ n → ✓{n'} x' → P n' x' → Q n' x' |}.
Next Obligation.
  intros M P Q n1 x1 x1' HPQ [x2 Hx1'] n2 x3 [x4 Hx3] ?; simpl in *.
  rewrite Hx3 (dist_le _ _ _ _ Hx1'); auto. intros ??.
  eapply HPQ; auto. exists (x2 ⋅ x4); by rewrite assoc.
Qed.
Next Obligation. intros M P Q [|n1] [|n2] x; auto with lia. Qed.
Definition uPred_impl_aux : { x | x = @uPred_impl_def }. by eexists. Qed.
Definition uPred_impl {M} := proj1_sig uPred_impl_aux M.
Definition uPred_impl_eq :
  @uPred_impl = @uPred_impl_def := proj2_sig uPred_impl_aux.

Program Definition uPred_forall_def {M A} (Ψ : A → uPred M) : uPred M :=
  {| uPred_holds n x := ∀ a, Ψ a n x |}.
Solve Obligations with naive_solver eauto 2 with uPred_def.
Definition uPred_forall_aux : { x | x = @uPred_forall_def }. by eexists. Qed.
Definition uPred_forall {M A} := proj1_sig uPred_forall_aux M A.
Definition uPred_forall_eq :
  @uPred_forall = @uPred_forall_def := proj2_sig uPred_forall_aux.

Program Definition uPred_exist_def {M A} (Ψ : A → uPred M) : uPred M :=
  {| uPred_holds n x := ∃ a, Ψ a n x |}.
Solve Obligations with naive_solver eauto 2 with uPred_def.
Definition uPred_exist_aux : { x | x = @uPred_exist_def }. by eexists. Qed.
Definition uPred_exist {M A} := proj1_sig uPred_exist_aux M A.
Definition uPred_exist_eq: @uPred_exist = @uPred_exist_def := proj2_sig uPred_exist_aux.

Program Definition uPred_internal_eq_def {M} {A : cofeT} (a1 a2 : A) : uPred M :=
  {| uPred_holds n x := a1 ≡{n}≡ a2 |}.
Solve Obligations with naive_solver eauto 2 using (dist_le (A:=A)).
Definition uPred_internal_eq_aux : { x | x = @uPred_internal_eq_def }. by eexists. Qed.
Definition uPred_internal_eq {M A} := proj1_sig uPred_internal_eq_aux M A.
Definition uPred_internal_eq_eq:
  @uPred_internal_eq = @uPred_internal_eq_def := proj2_sig uPred_internal_eq_aux.

Program Definition uPred_sep_def {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∃ x1 x2, x ≡{n}≡ x1 ⋅ x2 ∧ P n x1 ∧ Q n x2 |}.
Next Obligation.
  intros M P Q n x y (x1&x2&Hx&?&?) [z Hy].
  exists x1, (x2 ⋅ z); split_and?; eauto using uPred_mono, cmra_includedN_l.
  by rewrite Hy Hx assoc.
Qed.
Next Obligation.
  intros M P Q n1 n2 x (x1&x2&Hx&?&?) ?; rewrite {1}(dist_le _ _ _ _ Hx) // =>?.
  exists x1, x2; cofe_subst; split_and!;
    eauto using dist_le, uPred_closed, cmra_validN_op_l, cmra_validN_op_r.
Qed.
Definition uPred_sep_aux : { x | x = @uPred_sep_def }. by eexists. Qed.
Definition uPred_sep {M} := proj1_sig uPred_sep_aux M.
Definition uPred_sep_eq: @uPred_sep = @uPred_sep_def := proj2_sig uPred_sep_aux.

Program Definition uPred_wand_def {M} (P Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∀ n' x',
       n' ≤ n → ✓{n'} (x ⋅ x') → P n' x' → Q n' (x ⋅ x') |}.
Next Obligation.
  intros M P Q n x1 x1' HPQ ? n3 x3 ???; simpl in *.
  apply uPred_mono with (x1 ⋅ x3);
    eauto using cmra_validN_includedN, cmra_monoN_r, cmra_includedN_le.
Qed.
Next Obligation. naive_solver. Qed.
Definition uPred_wand_aux : { x | x = @uPred_wand_def }. by eexists. Qed.
Definition uPred_wand {M} := proj1_sig uPred_wand_aux M.
Definition uPred_wand_eq :
  @uPred_wand = @uPred_wand_def := proj2_sig uPred_wand_aux.

Program Definition uPred_always_def {M} (P : uPred M) : uPred M :=
  {| uPred_holds n x := P n (core x) |}.
Next Obligation.
  intros M; naive_solver eauto using uPred_mono, @cmra_core_monoN.
Qed.
Next Obligation. naive_solver eauto using uPred_closed, @cmra_core_validN. Qed.
Definition uPred_always_aux : { x | x = @uPred_always_def }. by eexists. Qed.
Definition uPred_always {M} := proj1_sig uPred_always_aux M.
Definition uPred_always_eq :
  @uPred_always = @uPred_always_def := proj2_sig uPred_always_aux.

Program Definition uPred_later_def {M} (P : uPred M) : uPred M :=
  {| uPred_holds n x := match n return _ with 0 => True | S n' => P n' x end |}.
Next Obligation.
  intros M P [|n] x1 x2; eauto using uPred_mono, cmra_includedN_S.
Qed.
Next Obligation.
  intros M P [|n1] [|n2] x; eauto using uPred_closed, cmra_validN_S with lia.
Qed.
Definition uPred_later_aux : { x | x = @uPred_later_def }. by eexists. Qed.
Definition uPred_later {M} := proj1_sig uPred_later_aux M.
Definition uPred_later_eq :
  @uPred_later = @uPred_later_def := proj2_sig uPred_later_aux.

Program Definition uPred_ownM_def {M : ucmraT} (a : M) : uPred M :=
  {| uPred_holds n x := a ≼{n} x |}.
Next Obligation.
  intros M a n x1 x [a' Hx1] [x2 ->].
  exists (a' ⋅ x2). by rewrite (assoc op) Hx1.
Qed.
Next Obligation. naive_solver eauto using cmra_includedN_le. Qed.
Definition uPred_ownM_aux : { x | x = @uPred_ownM_def }. by eexists. Qed.
Definition uPred_ownM {M} := proj1_sig uPred_ownM_aux M.
Definition uPred_ownM_eq :
  @uPred_ownM = @uPred_ownM_def := proj2_sig uPred_ownM_aux.

Program Definition uPred_cmra_valid_def {M} {A : cmraT} (a : A) : uPred M :=
  {| uPred_holds n x := ✓{n} a |}.
Solve Obligations with naive_solver eauto 2 using cmra_validN_le.
Definition uPred_cmra_valid_aux : { x | x = @uPred_cmra_valid_def }. by eexists. Qed.
Definition uPred_cmra_valid {M A} := proj1_sig uPred_cmra_valid_aux M A.
Definition uPred_cmra_valid_eq :
  @uPred_cmra_valid = @uPred_cmra_valid_def := proj2_sig uPred_cmra_valid_aux.

Program Definition uPred_bupd_def {M} (Q : uPred M) : uPred M :=
  {| uPred_holds n x := ∀ k yf,
      k ≤ n → ✓{k} (x ⋅ yf) → ∃ x', ✓{k} (x' ⋅ yf) ∧ Q k x' |}.
Next Obligation.
  intros M Q n x1 x2 HQ [x3 Hx] k yf Hk.
  rewrite (dist_le _ _ _ _ Hx); last lia. intros Hxy.
  destruct (HQ k (x3 ⋅ yf)) as (x'&?&?); [auto|by rewrite assoc|].
  exists (x' ⋅ x3); split; first by rewrite -assoc.
  apply uPred_mono with x'; eauto using cmra_includedN_l.
Qed.
Next Obligation. naive_solver. Qed.
Definition uPred_bupd_aux : { x | x = @uPred_bupd_def }. by eexists. Qed.
Definition uPred_bupd {M} := proj1_sig uPred_bupd_aux M.
Definition uPred_bupd_eq : @uPred_bupd = @uPred_bupd_def := proj2_sig uPred_bupd_aux.

Notation "■ φ" := (uPred_pure φ%C%type)
  (at level 20, right associativity) : uPred_scope.
Notation "x = y" := (uPred_pure (x%C%type = y%C%type)) : uPred_scope.
Notation "x ⊥ y" := (uPred_pure (x%C%type ⊥ y%C%type)) : uPred_scope.
Notation "'False'" := (uPred_pure False) : uPred_scope.
Notation "'True'" := (uPred_pure True) : uPred_scope.
Infix "∧" := uPred_and : uPred_scope.
Notation "(∧)" := uPred_and (only parsing) : uPred_scope.
Infix "∨" := uPred_or : uPred_scope.
Notation "(∨)" := uPred_or (only parsing) : uPred_scope.
Infix "→" := uPred_impl : uPred_scope.
Infix "∗" := uPred_sep (at level 80, right associativity) : uPred_scope.
Notation "(∗)" := uPred_sep (only parsing) : uPred_scope.
Notation "P -∗ Q" := (uPred_wand P Q)
  (at level 99, Q at level 200, right associativity) : uPred_scope.
Notation "∀ x .. y , P" :=
  (uPred_forall (λ x, .. (uPred_forall (λ y, P)) ..)%I)
  (at level 200, x binder, y binder, right associativity) : uPred_scope.
Notation "∃ x .. y , P" :=
  (uPred_exist (λ x, .. (uPred_exist (λ y, P)) ..)%I)
  (at level 200, x binder, y binder, right associativity) : uPred_scope.
Notation "□ P" := (uPred_always P)
  (at level 20, right associativity) : uPred_scope.
Notation "▷ P" := (uPred_later P)
  (at level 20, right associativity) : uPred_scope.
Infix "≡" := uPred_internal_eq : uPred_scope.
Notation "✓ x" := (uPred_cmra_valid x) (at level 20) : uPred_scope.
Notation "|==> Q" := (uPred_bupd Q)
  (at level 99, Q at level 200, format "|==>  Q") : uPred_scope.
Notation "P ==∗ Q" := (P ⊢ |==> Q)
  (at level 99, Q at level 200, only parsing) : C_scope.
Notation "P ==∗ Q" := (P -∗ |==> Q)%I
  (at level 99, Q at level 200, format "P  ==∗  Q") : uPred_scope.

Module uPred_primitive.
Definition unseal :=
  (uPred_pure_eq, uPred_and_eq, uPred_or_eq, uPred_impl_eq, uPred_forall_eq,
  uPred_exist_eq, uPred_internal_eq_eq, uPred_sep_eq, uPred_wand_eq, uPred_always_eq,
  uPred_later_eq, uPred_ownM_eq, uPred_cmra_valid_eq, uPred_bupd_eq).
Ltac unseal := rewrite !unseal /=.

Section primitive.
Context {M : ucmraT}.
Implicit Types φ : Prop.
Implicit Types P Q : uPred M.
Implicit Types A : Type.
Notation "P ⊢ Q" := (@uPred_entails M P%I Q%I). (* Force implicit argument M *)
Notation "P ⊣⊢ Q" := (equiv (A:=uPred M) P%I Q%I). (* Force implicit argument M *)
Arguments uPred_holds {_} !_ _ _ /.
Hint Immediate uPred_in_entails.

(** Non-expansiveness and setoid morphisms *)
Global Instance pure_proper : Proper (iff ==> (⊣⊢)) (@uPred_pure M).
Proof. intros φ1 φ2 Hφ. by unseal; split=> -[|n] ?; try apply Hφ. Qed.
Global Instance and_ne n : Proper (dist n ==> dist n ==> dist n) (@uPred_and M).
Proof.
  intros P P' HP Q Q' HQ; unseal; split=> x n' ??.
  split; (intros [??]; split; [by apply HP|by apply HQ]).
Qed.
Global Instance and_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_and M) := ne_proper_2 _.
Global Instance or_ne n : Proper (dist n ==> dist n ==> dist n) (@uPred_or M).
Proof.
  intros P P' HP Q Q' HQ; split=> x n' ??.
  unseal; split; (intros [?|?]; [left; by apply HP|right; by apply HQ]).
Qed.
Global Instance or_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_or M) := ne_proper_2 _.
Global Instance impl_ne n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_impl M).
Proof.
  intros P P' HP Q Q' HQ; split=> x n' ??.
  unseal; split; intros HPQ x' n'' ????; apply HQ, HPQ, HP; auto.
Qed.
Global Instance impl_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_impl M) := ne_proper_2 _.
Global Instance sep_ne n : Proper (dist n ==> dist n ==> dist n) (@uPred_sep M).
Proof.
  intros P P' HP Q Q' HQ; split=> n' x ??.
  unseal; split; intros (x1&x2&?&?&?); cofe_subst x;
    exists x1, x2; split_and!; try (apply HP || apply HQ);
    eauto using cmra_validN_op_l, cmra_validN_op_r.
Qed.
Global Instance sep_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_sep M) := ne_proper_2 _.
Global Instance wand_ne n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_wand M).
Proof.
  intros P P' HP Q Q' HQ; split=> n' x ??; unseal; split; intros HPQ x' n'' ???;
    apply HQ, HPQ, HP; eauto using cmra_validN_op_r.
Qed.
Global Instance wand_proper :
  Proper ((⊣⊢) ==> (⊣⊢) ==> (⊣⊢)) (@uPred_wand M) := ne_proper_2 _.
Global Instance internal_eq_ne (A : cofeT) n :
  Proper (dist n ==> dist n ==> dist n) (@uPred_internal_eq M A).
Proof.
  intros x x' Hx y y' Hy; split=> n' z; unseal; split; intros; simpl in *.
  - by rewrite -(dist_le _ _ _ _ Hx) -?(dist_le _ _ _ _ Hy); auto.
  - by rewrite (dist_le _ _ _ _ Hx) ?(dist_le _ _ _ _ Hy); auto.
Qed.
Global Instance internal_eq_proper (A : cofeT) :
  Proper ((≡) ==> (≡) ==> (⊣⊢)) (@uPred_internal_eq M A) := ne_proper_2 _.
Global Instance forall_ne A n :
  Proper (pointwise_relation _ (dist n) ==> dist n) (@uPred_forall M A).
Proof.
  by intros Ψ1 Ψ2 HΨ; unseal; split=> n' x; split; intros HP a; apply HΨ.
Qed.
Global Instance forall_proper A :
  Proper (pointwise_relation _ (⊣⊢) ==> (⊣⊢)) (@uPred_forall M A).
Proof.
  by intros Ψ1 Ψ2 HΨ; unseal; split=> n' x; split; intros HP a; apply HΨ.
Qed.
Global Instance exist_ne A n :
  Proper (pointwise_relation _ (dist n) ==> dist n) (@uPred_exist M A).
Proof.
  intros Ψ1 Ψ2 HΨ.
  unseal; split=> n' x ??; split; intros [a ?]; exists a; by apply HΨ.
Qed.
Global Instance exist_proper A :
  Proper (pointwise_relation _ (⊣⊢) ==> (⊣⊢)) (@uPred_exist M A).
Proof.
  intros Ψ1 Ψ2 HΨ.
  unseal; split=> n' x ?; split; intros [a ?]; exists a; by apply HΨ.
Qed.
Global Instance later_contractive : Contractive (@uPred_later M).
Proof.
  intros n P Q HPQ; unseal; split=> -[|n'] x ??; simpl; [done|].
  apply (HPQ n'); eauto using cmra_validN_S.
Qed.
Global Instance later_proper' :
  Proper ((⊣⊢) ==> (⊣⊢)) (@uPred_later M) := ne_proper _.
Global Instance always_ne n : Proper (dist n ==> dist n) (@uPred_always M).
Proof.
  intros P1 P2 HP.
  unseal; split=> n' x; split; apply HP; eauto using @cmra_core_validN.
Qed.
Global Instance always_proper :
  Proper ((⊣⊢) ==> (⊣⊢)) (@uPred_always M) := ne_proper _.
Global Instance ownM_ne n : Proper (dist n ==> dist n) (@uPred_ownM M).
Proof.
  intros a b Ha.
  unseal; split=> n' x ? /=. by rewrite (dist_le _ _ _ _ Ha); last lia.
Qed.
Global Instance ownM_proper: Proper ((≡) ==> (⊣⊢)) (@uPred_ownM M) := ne_proper _.
Global Instance cmra_valid_ne {A : cmraT} n :
Proper (dist n ==> dist n) (@uPred_cmra_valid M A).
Proof.
  intros a b Ha; unseal; split=> n' x ? /=.
  by rewrite (dist_le _ _ _ _ Ha); last lia.
Qed.
Global Instance cmra_valid_proper {A : cmraT} :
  Proper ((≡) ==> (⊣⊢)) (@uPred_cmra_valid M A) := ne_proper _.
Global Instance bupd_ne n : Proper (dist n ==> dist n) (@uPred_bupd M).
Proof.
  intros P Q HPQ.
  unseal; split=> n' x; split; intros HP k yf ??;
    destruct (HP k yf) as (x'&?&?); auto;
    exists x'; split; auto; apply HPQ; eauto using cmra_validN_op_l.
Qed.
Global Instance bupd_proper : Proper ((≡) ==> (≡)) (@uPred_bupd M) := ne_proper _.

(** Introduction and elimination rules *)
Lemma pure_intro φ P : φ → P ⊢ ■ φ.
Proof. by intros ?; unseal; split. Qed.
Lemma pure_elim φ Q R : (Q ⊢ ■ φ) → (φ → Q ⊢ R) → Q ⊢ R.
Proof.
  unseal; intros HQP HQR; split=> n x ??; apply HQR; first eapply HQP; eauto.
Qed.
Lemma pure_forall_2 {A} (φ : A → Prop) : (∀ x : A, ■ φ x) ⊢ ■ (∀ x : A, φ x).
Proof. by unseal. Qed.

Lemma and_elim_l P Q : P ∧ Q ⊢ P.
Proof. by unseal; split=> n x ? [??]. Qed.
Lemma and_elim_r P Q : P ∧ Q ⊢ Q.
Proof. by unseal; split=> n x ? [??]. Qed.
Lemma and_intro P Q R : (P ⊢ Q) → (P ⊢ R) → P ⊢ Q ∧ R.
Proof. intros HQ HR; unseal; split=> n x ??; by split; [apply HQ|apply HR]. Qed.

Lemma or_intro_l P Q : P ⊢ P ∨ Q.
Proof. unseal; split=> n x ??; left; auto. Qed.
Lemma or_intro_r P Q : Q ⊢ P ∨ Q.
Proof. unseal; split=> n x ??; right; auto. Qed.
Lemma or_elim P Q R : (P ⊢ R) → (Q ⊢ R) → P ∨ Q ⊢ R.
Proof. intros HP HQ; unseal; split=> n x ? [?|?]. by apply HP. by apply HQ. Qed.

Lemma impl_intro_r P Q R : (P ∧ Q ⊢ R) → P ⊢ Q → R.
Proof.
  unseal; intros HQ; split=> n x ?? n' x' ????. apply HQ;
    naive_solver eauto using uPred_mono, uPred_closed, cmra_included_includedN.
Qed.
Lemma impl_elim P Q R : (P ⊢ Q → R) → (P ⊢ Q) → P ⊢ R.
Proof. by unseal; intros HP HP'; split=> n x ??; apply HP with n x, HP'. Qed.

Lemma forall_intro {A} P (Ψ : A → uPred M): (∀ a, P ⊢ Ψ a) → P ⊢ ∀ a, Ψ a.
Proof. unseal; intros HPΨ; split=> n x ?? a; by apply HPΨ. Qed.
Lemma forall_elim {A} {Ψ : A → uPred M} a : (∀ a, Ψ a) ⊢ Ψ a.
Proof. unseal; split=> n x ? HP; apply HP. Qed.

Lemma exist_intro {A} {Ψ : A → uPred M} a : Ψ a ⊢ ∃ a, Ψ a.
Proof. unseal; split=> n x ??; by exists a. Qed.
Lemma exist_elim {A} (Φ : A → uPred M) Q : (∀ a, Φ a ⊢ Q) → (∃ a, Φ a) ⊢ Q.
Proof. unseal; intros HΦΨ; split=> n x ? [a ?]; by apply HΦΨ with a. Qed.

Lemma internal_eq_refl {A : cofeT} (a : A) : True ⊢ a ≡ a.
Proof. unseal; by split=> n x ??; simpl. Qed.
Lemma internal_eq_rewrite {A : cofeT} a b (Ψ : A → uPred M) P
  {HΨ : ∀ n, Proper (dist n ==> dist n) Ψ} : (P ⊢ a ≡ b) → (P ⊢ Ψ a) → P ⊢ Ψ b.
Proof.
  unseal; intros Hab Ha; split=> n x ??. apply HΨ with n a; auto.
  - by symmetry; apply Hab with x.
  - by apply Ha.
Qed.
Lemma internal_eq_rewrite_contractive {A : cofeT} a b (Ψ : A → uPred M) P
  {HΨ : Contractive Ψ} : (P ⊢ ▷ (a ≡ b)) → (P ⊢ Ψ a) → P ⊢ Ψ b.
Proof.
  unseal; intros Hab Ha; split=> n x ??. apply HΨ with n a; auto.
  - destruct n; intros m ?; first omega. apply (dist_le n); last omega.
    symmetry. by destruct Hab as [Hab]; eapply (Hab (S n)).
  - by apply Ha.
Qed.

(* BI connectives *)
Lemma sep_mono P P' Q Q' : (P ⊢ Q) → (P' ⊢ Q') → P ∗ P' ⊢ Q ∗ Q'.
Proof.
  intros HQ HQ'; unseal.
  split; intros n' x ? (x1&x2&?&?&?); exists x1,x2; cofe_subst x;
    eauto 7 using cmra_validN_op_l, cmra_validN_op_r, uPred_in_entails.
Qed.
Lemma True_sep_1 P : P ⊢ True ∗ P.
Proof.
  unseal; split; intros n x ??. exists (core x), x. by rewrite cmra_core_l.
Qed.
Lemma True_sep_2 P : True ∗ P ⊢ P.
Proof.
  unseal; split; intros n x ? (x1&x2&?&_&?); cofe_subst;
    eauto using uPred_mono, cmra_includedN_r.
Qed.
Lemma sep_comm' P Q : P ∗ Q ⊢ Q ∗ P.
Proof.
  unseal; split; intros n x ? (x1&x2&?&?&?); exists x2, x1; by rewrite (comm op).
Qed.
Lemma sep_assoc' P Q R : (P ∗ Q) ∗ R ⊢ P ∗ (Q ∗ R).
Proof.
  unseal; split; intros n x ? (x1&x2&Hx&(y1&y2&Hy&?&?)&?).
  exists y1, (y2 ⋅ x2); split_and?; auto.
  + by rewrite (assoc op) -Hy -Hx.
  + by exists y2, x2.
Qed.
Lemma wand_intro_r P Q R : (P ∗ Q ⊢ R) → P ⊢ Q -∗ R.
Proof.
  unseal=> HPQR; split=> n x ?? n' x' ???; apply HPQR; auto.
  exists x, x'; split_and?; auto.
  eapply uPred_closed with n; eauto using cmra_validN_op_l.
Qed.
Lemma wand_elim_l' P Q R : (P ⊢ Q -∗ R) → P ∗ Q ⊢ R.
Proof.
  unseal =>HPQR. split; intros n x ? (?&?&?&?&?). cofe_subst.
  eapply HPQR; eauto using cmra_validN_op_l.
Qed.

(* Always *)
Lemma always_mono P Q : (P ⊢ Q) → □ P ⊢ □ Q.
Proof. intros HP; unseal; split=> n x ? /=. by apply HP, cmra_core_validN. Qed.
Lemma always_elim P : □ P ⊢ P.
Proof.
  unseal; split=> n x ? /=.
  eauto using uPred_mono, @cmra_included_core, cmra_included_includedN.
Qed.
Lemma always_idemp P : □ P ⊢ □ □ P.
Proof. unseal; split=> n x ?? /=. by rewrite cmra_core_idemp. Qed.

Lemma always_pure_2 φ : ■ φ ⊢ □ ■ φ.
Proof. by unseal. Qed.
Lemma always_forall_2 {A} (Ψ : A → uPred M) : (∀ a, □ Ψ a) ⊢ (□ ∀ a, Ψ a).
Proof. by unseal. Qed.
Lemma always_exist_1 {A} (Ψ : A → uPred M) : (□ ∃ a, Ψ a) ⊢ (∃ a, □ Ψ a).
Proof. by unseal. Qed.

Lemma always_and_sep_1 P Q : □ (P ∧ Q) ⊢ □ (P ∗ Q).
Proof.
  unseal; split=> n x ? [??].
  exists (core x), (core x); rewrite -cmra_core_dup; auto.
Qed.
Lemma always_and_sep_l_1 P Q : □ P ∧ Q ⊢ □ P ∗ Q.
Proof.
  unseal; split=> n x ? [??]; exists (core x), x; simpl in *.
  by rewrite cmra_core_l cmra_core_idemp.
Qed.

(* Later *)
Lemma later_mono P Q : (P ⊢ Q) → ▷ P ⊢ ▷ Q.
Proof.
  unseal=> HP; split=>-[|n] x ??; [done|apply HP; eauto using cmra_validN_S].
Qed.
Lemma löb P : (▷ P → P) ⊢ P.
Proof.
  unseal; split=> n x ? HP; induction n as [|n IH]; [by apply HP|].
  apply HP, IH, uPred_closed with (S n); eauto using cmra_validN_S.
Qed.
Lemma later_forall_2 {A} (Φ : A → uPred M) : (∀ a, ▷ Φ a) ⊢ ▷ ∀ a, Φ a.
Proof. unseal; by split=> -[|n] x. Qed.
Lemma later_exist_false {A} (Φ : A → uPred M) :
  (▷ ∃ a, Φ a) ⊢ ▷ False ∨ (∃ a, ▷ Φ a).
Proof. unseal; split=> -[|[|n]] x /=; eauto. Qed.
Lemma later_sep P Q : ▷ (P ∗ Q) ⊣⊢ ▷ P ∗ ▷ Q.
Proof.
  unseal; split=> n x ?; split.
  - destruct n as [|n]; simpl.
    { by exists x, (core x); rewrite cmra_core_r. }
    intros (x1&x2&Hx&?&?); destruct (cmra_extend n x x1 x2)
      as (y1&y2&Hx'&Hy1&Hy2); eauto using cmra_validN_S; simpl in *.
    exists y1, y2; split; [by rewrite Hx'|by rewrite Hy1 Hy2].
  - destruct n as [|n]; simpl; [done|intros (x1&x2&Hx&?&?)].
    exists x1, x2; eauto using dist_S.
Qed.
Lemma later_false_excluded_middle P : ▷ P ⊢ ▷ False ∨ (▷ False → P).
Proof.
  unseal; split=> -[|n] x ? /= HP; [by left|right].
  intros [|n'] x' ????; [|done].
  eauto using uPred_closed, uPred_mono, cmra_included_includedN.
Qed.
Lemma always_later P : □ ▷ P ⊣⊢ ▷ □ P.
Proof. by unseal. Qed.

(* Own *)
Lemma ownM_op (a1 a2 : M) :
  uPred_ownM (a1 ⋅ a2) ⊣⊢ uPred_ownM a1 ∗ uPred_ownM a2.
Proof.
  unseal; split=> n x ?; split.
  - intros [z ?]; exists a1, (a2 ⋅ z); split; [by rewrite (assoc op)|].
    split. by exists (core a1); rewrite cmra_core_r. by exists z.
  - intros (y1&y2&Hx&[z1 Hy1]&[z2 Hy2]); exists (z1 ⋅ z2).
    by rewrite (assoc op _ z1) -(comm op z1) (assoc op z1)
      -(assoc op _ a2) (comm op z1) -Hy1 -Hy2.
Qed.
Lemma always_ownM_core (a : M) : uPred_ownM a ⊢ □ uPred_ownM (core a).
Proof.
  split=> n x /=; unseal; intros Hx. simpl. by apply cmra_core_monoN.
Qed.
Lemma ownM_empty : True ⊢ uPred_ownM ∅.
Proof. unseal; split=> n x ??; by  exists x; rewrite left_id. Qed.
Lemma later_ownM a : ▷ uPred_ownM a ⊢ ∃ b, uPred_ownM b ∧ ▷ (a ≡ b).
Proof.
  unseal; split=> -[|n] x /= ? Hax; first by eauto using ucmra_unit_leastN.
  destruct Hax as [y ?].
  destruct (cmra_extend n x a y) as (a'&y'&Hx&?&?); auto using cmra_validN_S.
  exists a'. rewrite Hx. eauto using cmra_includedN_l.
Qed.

(* Valid *)
Lemma ownM_valid (a : M) : uPred_ownM a ⊢ ✓ a.
Proof.
  unseal; split=> n x Hv [a' ?]; cofe_subst; eauto using cmra_validN_op_l.
Qed.
Lemma cmra_valid_intro {A : cmraT} (a : A) : ✓ a → True ⊢ ✓ a.
Proof. unseal=> ?; split=> n x ? _ /=; by apply cmra_valid_validN. Qed.
Lemma cmra_valid_elim {A : cmraT} (a : A) : ¬ ✓{0} a → ✓ a ⊢ False.
Proof. unseal=> Ha; split=> n x ??; apply Ha, cmra_validN_le with n; auto. Qed.
Lemma always_cmra_valid_1 {A : cmraT} (a : A) : ✓ a ⊢ □ ✓ a.
Proof. by unseal. Qed.
Lemma cmra_valid_weaken {A : cmraT} (a b : A) : ✓ (a ⋅ b) ⊢ ✓ a.
Proof. unseal; split=> n x _; apply cmra_validN_op_l. Qed.

(* Basic update modality *)
Lemma bupd_intro P : P ==∗ P.
Proof.
  unseal. split=> n x ? HP k yf ?; exists x; split; first done.
  apply uPred_closed with n; eauto using cmra_validN_op_l.
Qed.
Lemma bupd_mono P Q : (P ⊢ Q) → (|==> P) ==∗ Q.
Proof.
  unseal. intros HPQ; split=> n x ? HP k yf ??.
  destruct (HP k yf) as (x'&?&?); eauto.
  exists x'; split; eauto using uPred_in_entails, cmra_validN_op_l.
Qed.
Lemma bupd_trans P : (|==> |==> P) ==∗ P.
Proof. unseal; split; naive_solver. Qed.
Lemma bupd_frame_r P R : (|==> P) ∗ R ==∗ P ∗ R.
Proof.
  unseal; split; intros n x ? (x1&x2&Hx&HP&?) k yf ??.
  destruct (HP k (x2 ⋅ yf)) as (x'&?&?); eauto.
  { by rewrite assoc -(dist_le _ _ _ _ Hx); last lia. }
  exists (x' ⋅ x2); split; first by rewrite -assoc.
  exists x', x2; split_and?; auto.
  apply uPred_closed with n; eauto 3 using cmra_validN_op_l, cmra_validN_op_r.
Qed.
Lemma bupd_ownM_updateP x (Φ : M → Prop) :
  x ~~>: Φ → uPred_ownM x ==∗ ∃ y, ■ Φ y ∧ uPred_ownM y.
Proof.
  unseal=> Hup; split=> n x2 ? [x3 Hx] k yf ??.
  destruct (Hup k (Some (x3 ⋅ yf))) as (y&?&?); simpl in *.
  { rewrite /= assoc -(dist_le _ _ _ _ Hx); auto. }
  exists (y ⋅ x3); split; first by rewrite -assoc.
  exists y; eauto using cmra_includedN_l.
Qed.

(* Products *)
Lemma prod_equivI {A B : cofeT} (x y : A * B) : x ≡ y ⊣⊢ x.1 ≡ y.1 ∧ x.2 ≡ y.2.
Proof. by unseal. Qed.
Lemma prod_validI {A B : cmraT} (x : A * B) : ✓ x ⊣⊢ ✓ x.1 ∧ ✓ x.2.
Proof. by unseal. Qed.

(* Later *)
Lemma later_equivI {A : cofeT} (x y : A) : Next x ≡ Next y ⊣⊢ ▷ (x ≡ y).
Proof. by unseal. Qed.

(* Discrete *)
Lemma discrete_valid {A : cmraT} `{!CMRADiscrete A} (a : A) : ✓ a ⊣⊢ ■ ✓ a.
Proof. unseal; split=> n x _. by rewrite /= -cmra_discrete_valid_iff. Qed.
Lemma timeless_eq {A : cofeT} (a b : A) : Timeless a → a ≡ b ⊣⊢ ■ (a ≡ b).
Proof.
  unseal=> ?. apply (anti_symm (⊢)); split=> n x ?; by apply (timeless_iff n).
Qed.

(* Option *)
Lemma option_equivI {A : cofeT} (mx my : option A) :
  mx ≡ my ⊣⊢ match mx, my with
             | Some x, Some y => x ≡ y | None, None => True | _, _ => False
             end.
Proof.
  unseal. do 2 split. by destruct 1. by destruct mx, my; try constructor.
Qed.
Lemma option_validI {A : cmraT} (mx : option A) :
  ✓ mx ⊣⊢ match mx with Some x => ✓ x | None => True end.
Proof. unseal. by destruct mx. Qed.

(* Functions *)
Lemma cofe_funC_equivI {A B} (f g : A -c> B) : f ≡ g ⊣⊢ ∀ x, f x ≡ g x.
Proof. by unseal. Qed.
Lemma cofe_morC_equivI {A B : cofeT} (f g : A -n> B) : f ≡ g ⊣⊢ ∀ x, f x ≡ g x.
Proof. by unseal. Qed.
End primitive.
End uPred_primitive.
