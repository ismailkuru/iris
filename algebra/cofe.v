From iris.algebra Require Export base.

(** This files defines (a shallow embedding of) the category of COFEs:
    Complete ordered families of equivalences. This is a cartesian closed
    category, and mathematically speaking, the entire development lives
    in this category. However, we will generally prefer to work with raw
    Coq functions plus some registered Proper instances for non-expansiveness.
    This makes writing such functions much easier. It turns out that it many 
    cases, we do not even need non-expansiveness.

    In principle, it would be possible to perform a large part of the
    development on OFEs, i.e., on bisected metric spaces that are not
    necessary complete. This is because the function space A → B has a
    completion if B has one - for A, the metric itself suffices.
    That would result in a simplification of some constructions, becuase
    no completion would have to be provided. However, on the other hand,
    we would have to introduce the notion of OFEs into our alebraic
    hierarchy, which we'd rather avoid. Furthermore, on paper, justifying
    this mix of OFEs and COFEs is a little fuzzy.
*)

(** Unbundeled version *)
Class Dist A := dist : nat → relation A.
Instance: Params (@dist) 3.
Notation "x ≡{ n }≡ y" := (dist n x y)
  (at level 70, n at next level, format "x  ≡{ n }≡  y").
Hint Extern 0 (_ ≡{_}≡ _) => reflexivity.
Hint Extern 0 (_ ≡{_}≡ _) => symmetry; assumption.

Tactic Notation "cofe_subst" ident(x) :=
  repeat match goal with
  | _ => progress simplify_eq/=
  | H:@dist ?A ?d ?n x _ |- _ => setoid_subst_aux (@dist A d n) x
  | H:@dist ?A ?d ?n _ x |- _ => symmetry in H;setoid_subst_aux (@dist A d n) x
  end.
Tactic Notation "cofe_subst" :=
  repeat match goal with
  | _ => progress simplify_eq/=
  | H:@dist ?A ?d ?n ?x _ |- _ => setoid_subst_aux (@dist A d n) x
  | H:@dist ?A ?d ?n _ ?x |- _ => symmetry in H;setoid_subst_aux (@dist A d n) x
  end.

Record chain (A : Type) `{Dist A} := {
  chain_car :> nat → A;
  chain_cauchy n i : n ≤ i → chain_car i ≡{n}≡ chain_car n
}.
Arguments chain_car {_ _} _ _.
Arguments chain_cauchy {_ _} _ _ _ _.
Class Compl A `{Dist A} := compl : chain A → A.

Record CofeMixin A `{Equiv A, Compl A} := {
  mixin_equiv_dist x y : x ≡ y ↔ ∀ n, x ≡{n}≡ y;
  mixin_dist_equivalence n : Equivalence (dist n);
  mixin_dist_S n x y : x ≡{S n}≡ y → x ≡{n}≡ y;
  mixin_conv_compl n c : compl c ≡{n}≡ c n
}.
Class Contractive `{Dist A, Dist B} (f : A → B) :=
  contractive n x y : (∀ i, i < n → x ≡{i}≡ y) → f x ≡{n}≡ f y.

(** Bundeled version *)
Structure cofeT := CofeT' {
  cofe_car :> Type;
  cofe_equiv : Equiv cofe_car;
  cofe_dist : Dist cofe_car;
  cofe_compl : Compl cofe_car;
  cofe_mixin : CofeMixin cofe_car;
  _ : Type
}.
Arguments CofeT' _ {_ _ _} _ _.
Notation CofeT A m := (CofeT' A m A).
Add Printing Constructor cofeT.
Hint Extern 0 (Equiv _) => eapply (@cofe_equiv _) : typeclass_instances.
Hint Extern 0 (Dist _) => eapply (@cofe_dist _) : typeclass_instances.
Hint Extern 0 (Compl _) => eapply (@cofe_compl _) : typeclass_instances.
Arguments cofe_car : simpl never.
Arguments cofe_equiv : simpl never.
Arguments cofe_dist : simpl never.
Arguments cofe_compl : simpl never.
Arguments cofe_mixin : simpl never.

(** Lifting properties from the mixin *)
Section cofe_mixin.
  Context {A : cofeT}.
  Implicit Types x y : A.
  Lemma equiv_dist x y : x ≡ y ↔ ∀ n, x ≡{n}≡ y.
  Proof. apply (mixin_equiv_dist _ (cofe_mixin A)). Qed.
  Global Instance dist_equivalence n : Equivalence (@dist A _ n).
  Proof. apply (mixin_dist_equivalence _ (cofe_mixin A)). Qed.
  Lemma dist_S n x y : x ≡{S n}≡ y → x ≡{n}≡ y.
  Proof. apply (mixin_dist_S _ (cofe_mixin A)). Qed.
  Lemma conv_compl n (c : chain A) : compl c ≡{n}≡ c n.
  Proof. apply (mixin_conv_compl _ (cofe_mixin A)). Qed.
End cofe_mixin.

Hint Extern 1 (_ ≡{_}≡ _) => apply equiv_dist; assumption.

(** Discrete COFEs and Timeless elements *)
(* TODO: On paper, We called these "discrete elements". I think that makes
   more sense. *)
Class Timeless `{Equiv A, Dist A} (x : A) := timeless y : x ≡{0}≡ y → x ≡ y.
Arguments timeless {_ _ _} _ {_} _ _.
Class Discrete (A : cofeT) := discrete_timeless (x : A) :> Timeless x.

(** General properties *)
Section cofe.
  Context {A : cofeT}.
  Implicit Types x y : A.
  Global Instance cofe_equivalence : Equivalence ((≡) : relation A).
  Proof.
    split.
    - by intros x; rewrite equiv_dist.
    - by intros x y; rewrite !equiv_dist.
    - by intros x y z; rewrite !equiv_dist; intros; trans y.
  Qed.
  Global Instance dist_ne n : Proper (dist n ==> dist n ==> iff) (@dist A _ n).
  Proof.
    intros x1 x2 ? y1 y2 ?; split; intros.
    - by trans x1; [|trans y1].
    - by trans x2; [|trans y2].
  Qed.
  Global Instance dist_proper n : Proper ((≡) ==> (≡) ==> iff) (@dist A _ n).
  Proof.
    by move => x1 x2 /equiv_dist Hx y1 y2 /equiv_dist Hy; rewrite (Hx n) (Hy n).
  Qed.
  Global Instance dist_proper_2 n x : Proper ((≡) ==> iff) (dist n x).
  Proof. by apply dist_proper. Qed.
  Lemma dist_le n n' x y : x ≡{n}≡ y → n' ≤ n → x ≡{n'}≡ y.
  Proof. induction 2; eauto using dist_S. Qed.
  Lemma dist_le' n n' x y : n' ≤ n → x ≡{n}≡ y → x ≡{n'}≡ y.
  Proof. intros; eauto using dist_le. Qed.
  Instance ne_proper {B : cofeT} (f : A → B)
    `{!∀ n, Proper (dist n ==> dist n) f} : Proper ((≡) ==> (≡)) f | 100.
  Proof. by intros x1 x2; rewrite !equiv_dist; intros Hx n; rewrite (Hx n). Qed.
  Instance ne_proper_2 {B C : cofeT} (f : A → B → C)
    `{!∀ n, Proper (dist n ==> dist n ==> dist n) f} :
    Proper ((≡) ==> (≡) ==> (≡)) f | 100.
  Proof.
     unfold Proper, respectful; setoid_rewrite equiv_dist.
     by intros x1 x2 Hx y1 y2 Hy n; rewrite (Hx n) (Hy n).
  Qed.
  Lemma contractive_S {B : cofeT} (f : A → B) `{!Contractive f} n x y :
    x ≡{n}≡ y → f x ≡{S n}≡ f y.
  Proof. eauto using contractive, dist_le with omega. Qed.
  Lemma contractive_0 {B : cofeT} (f : A → B) `{!Contractive f} x y :
    f x ≡{0}≡ f y.
  Proof. eauto using contractive with omega. Qed.
  Global Instance contractive_ne {B : cofeT} (f : A → B) `{!Contractive f} n :
    Proper (dist n ==> dist n) f | 100.
  Proof. by intros x y ?; apply dist_S, contractive_S. Qed.
  Global Instance contractive_proper {B : cofeT} (f : A → B) `{!Contractive f} :
    Proper ((≡) ==> (≡)) f | 100 := _.

  Lemma conv_compl' n (c : chain A) : compl c ≡{n}≡ c (S n).
  Proof.
    transitivity (c n); first by apply conv_compl. symmetry.
    apply chain_cauchy. omega.
  Qed.
  Lemma timeless_iff n (x : A) `{!Timeless x} y : x ≡ y ↔ x ≡{n}≡ y.
  Proof.
    split; intros; auto. apply (timeless _), dist_le with n; auto with lia.
  Qed.
End cofe.

Instance const_contractive {A B : cofeT} (x : A) : Contractive (@const A B x).
Proof. by intros n y1 y2. Qed.

(** Mapping a chain *)
Program Definition chain_map `{Dist A, Dist B} (f : A → B)
    `{!∀ n, Proper (dist n ==> dist n) f} (c : chain A) : chain B :=
  {| chain_car n := f (c n) |}.
Next Obligation. by intros ? A ? B f Hf c n i ?; apply Hf, chain_cauchy. Qed.

(** Fixpoint *)
Program Definition fixpoint_chain {A : cofeT} `{Inhabited A} (f : A → A)
  `{!Contractive f} : chain A := {| chain_car i := Nat.iter (S i) f inhabitant |}.
Next Obligation.
  intros A ? f ? n.
  induction n as [|n IH]; intros [|i] ?; simpl in *; try reflexivity || omega.
  - apply (contractive_0 f).
  - apply (contractive_S f), IH; auto with omega.
Qed.

Program Definition fixpoint_def {A : cofeT} `{Inhabited A} (f : A → A)
  `{!Contractive f} : A := compl (fixpoint_chain f).
Definition fixpoint_aux : { x | x = @fixpoint_def }. by eexists. Qed.
Definition fixpoint {A AiH} f {Hf} := proj1_sig fixpoint_aux A AiH f Hf.
Definition fixpoint_eq : @fixpoint = @fixpoint_def := proj2_sig fixpoint_aux.

Section fixpoint.
  Context {A : cofeT} `{Inhabited A} (f : A → A) `{!Contractive f}.

  Lemma fixpoint_unfold : fixpoint f ≡ f (fixpoint f).
  Proof.
    apply equiv_dist=>n.
    rewrite fixpoint_eq /fixpoint_def (conv_compl n (fixpoint_chain f)) //.
    induction n as [|n IH]; simpl; eauto using contractive_0, contractive_S.
  Qed.

  Lemma fixpoint_unique (x : A) : x ≡ f x → x ≡ fixpoint f.
  Proof.
    rewrite !equiv_dist=> Hx n. induction n as [|n IH]; simpl in *.
    - rewrite Hx fixpoint_unfold; eauto using contractive_0.
    - rewrite Hx fixpoint_unfold. apply (contractive_S _), IH.
  Qed.

  Lemma fixpoint_ne (g : A → A) `{!Contractive g} n :
    (∀ z, f z ≡{n}≡ g z) → fixpoint f ≡{n}≡ fixpoint g.
  Proof.
    intros Hfg. rewrite fixpoint_eq /fixpoint_def
      (conv_compl n (fixpoint_chain f)) (conv_compl n (fixpoint_chain g)) /=.
    induction n as [|n IH]; simpl in *; [by rewrite !Hfg|].
    rewrite Hfg; apply contractive_S, IH; auto using dist_S.
  Qed.
  Lemma fixpoint_proper (g : A → A) `{!Contractive g} :
    (∀ x, f x ≡ g x) → fixpoint f ≡ fixpoint g.
  Proof. setoid_rewrite equiv_dist; naive_solver eauto using fixpoint_ne. Qed.
End fixpoint.

(** Function space *)
(* We make [cofe_fun] a definition so that we can register it as a canonical
structure. *)
Definition cofe_fun (A : Type) (B : cofeT) := A → B.

Section cofe_fun.
  Context {A : Type} {B : cofeT}.
  Instance cofe_fun_equiv : Equiv (cofe_fun A B) := λ f g, ∀ x, f x ≡ g x.
  Instance cofe_fun_dist : Dist (cofe_fun A B) := λ n f g, ∀ x, f x ≡{n}≡ g x.
  Program Definition cofe_fun_chain `(c : chain (cofe_fun A B))
    (x : A) : chain B := {| chain_car n := c n x |}.
  Next Obligation. intros c x n i ?. by apply (chain_cauchy c). Qed.
  Program Instance cofe_fun_compl : Compl (cofe_fun A B) := λ c x,
    compl (cofe_fun_chain c x).
  Definition cofe_fun_cofe_mixin : CofeMixin (cofe_fun A B).
  Proof.
    split.
    - intros f g; split; [intros Hfg n k; apply equiv_dist, Hfg|].
      intros Hfg k; apply equiv_dist=> n; apply Hfg.
    - intros n; split.
      + by intros f x.
      + by intros f g ? x.
      + by intros f g h ?? x; trans (g x).
    - by intros n f g ? x; apply dist_S.
    - intros n c x. apply (conv_compl n (cofe_fun_chain c x)).
  Qed.
  Canonical Structure cofe_funC := CofeT (cofe_fun A B) cofe_fun_cofe_mixin.
End cofe_fun.

Arguments cofe_funC : clear implicits.
Notation "A -c> B" :=
  (cofe_funC A B) (at level 99, B at level 200, right associativity).
Instance cofe_fun_inhabited {A} {B : cofeT} `{Inhabited B} :
  Inhabited (A -c> B) := populate (λ _, inhabitant).

(** Non-expansive function space *)
Record cofe_mor (A B : cofeT) : Type := CofeMor {
  cofe_mor_car :> A → B;
  cofe_mor_ne n : Proper (dist n ==> dist n) cofe_mor_car
}.
Arguments CofeMor {_ _} _ {_}.
Add Printing Constructor cofe_mor.
Existing Instance cofe_mor_ne.

Notation "'λne' x .. y , t" :=
  (@CofeMor _ _ (λ x, .. (@CofeMor _ _ (λ y, t) _) ..) _)
  (at level 200, x binder, y binder, right associativity).

Section cofe_mor.
  Context {A B : cofeT}.
  Global Instance cofe_mor_proper (f : cofe_mor A B) : Proper ((≡) ==> (≡)) f.
  Proof. apply ne_proper, cofe_mor_ne. Qed.
  Instance cofe_mor_equiv : Equiv (cofe_mor A B) := λ f g, ∀ x, f x ≡ g x.
  Instance cofe_mor_dist : Dist (cofe_mor A B) := λ n f g, ∀ x, f x ≡{n}≡ g x.
  Program Definition cofe_mor_chain `(c : chain (cofe_mor A B))
    (x : A) : chain B := {| chain_car n := c n x |}.
  Next Obligation. intros c x n i ?. by apply (chain_cauchy c). Qed.
  Program Instance cofe_mor_compl : Compl (cofe_mor A B) := λ c,
    {| cofe_mor_car x := compl (cofe_mor_chain c x) |}.
  Next Obligation.
    intros c n x y Hx. by rewrite (conv_compl n (cofe_mor_chain c x))
      (conv_compl n (cofe_mor_chain c y)) /= Hx.
  Qed.
  Definition cofe_mor_cofe_mixin : CofeMixin (cofe_mor A B).
  Proof.
    split.
    - intros f g; split; [intros Hfg n k; apply equiv_dist, Hfg|].
      intros Hfg k; apply equiv_dist=> n; apply Hfg.
    - intros n; split.
      + by intros f x.
      + by intros f g ? x.
      + by intros f g h ?? x; trans (g x).
    - by intros n f g ? x; apply dist_S.
    - intros n c x; simpl.
      by rewrite (conv_compl n (cofe_mor_chain c x)) /=.
  Qed.
  Canonical Structure cofe_morC := CofeT (cofe_mor A B) cofe_mor_cofe_mixin.

  Global Instance cofe_mor_car_ne n :
    Proper (dist n ==> dist n ==> dist n) (@cofe_mor_car A B).
  Proof. intros f g Hfg x y Hx; rewrite Hx; apply Hfg. Qed.
  Global Instance cofe_mor_car_proper :
    Proper ((≡) ==> (≡) ==> (≡)) (@cofe_mor_car A B) := ne_proper_2 _.
  Lemma cofe_mor_ext (f g : cofe_mor A B) : f ≡ g ↔ ∀ x, f x ≡ g x.
  Proof. done. Qed.
End cofe_mor.

Arguments cofe_morC : clear implicits.
Notation "A -n> B" :=
  (cofe_morC A B) (at level 99, B at level 200, right associativity).
Instance cofe_mor_inhabited {A B : cofeT} `{Inhabited B} :
  Inhabited (A -n> B) := populate (λne _, inhabitant).

(** Identity and composition and constant function *)
Definition cid {A} : A -n> A := CofeMor id.
Instance: Params (@cid) 1.
Definition cconst {A B : cofeT} (x : B) : A -n> B := CofeMor (const x).
Instance: Params (@cconst) 2.

Definition ccompose {A B C}
  (f : B -n> C) (g : A -n> B) : A -n> C := CofeMor (f ∘ g).
Instance: Params (@ccompose) 3.
Infix "◎" := ccompose (at level 40, left associativity).
Lemma ccompose_ne {A B C} (f1 f2 : B -n> C) (g1 g2 : A -n> B) n :
  f1 ≡{n}≡ f2 → g1 ≡{n}≡ g2 → f1 ◎ g1 ≡{n}≡ f2 ◎ g2.
Proof. by intros Hf Hg x; rewrite /= (Hg x) (Hf (g2 x)). Qed.

(* Function space maps *)
Definition cofe_mor_map {A A' B B'} (f : A' -n> A) (g : B -n> B')
  (h : A -n> B) : A' -n> B' := g ◎ h ◎ f.
Instance cofe_mor_map_ne {A A' B B'} n :
  Proper (dist n ==> dist n ==> dist n ==> dist n) (@cofe_mor_map A A' B B').
Proof. intros ??? ??? ???. by repeat apply ccompose_ne. Qed.

Definition cofe_morC_map {A A' B B'} (f : A' -n> A) (g : B -n> B') :
  (A -n> B) -n> (A' -n>  B') := CofeMor (cofe_mor_map f g).
Instance cofe_morC_map_ne {A A' B B'} n :
  Proper (dist n ==> dist n ==> dist n) (@cofe_morC_map A A' B B').
Proof.
  intros f f' Hf g g' Hg ?. rewrite /= /cofe_mor_map.
  by repeat apply ccompose_ne.
Qed.

(** unit *)
Section unit.
  Instance unit_dist : Dist unit := λ _ _ _, True.
  Instance unit_compl : Compl unit := λ _, ().
  Definition unit_cofe_mixin : CofeMixin unit.
  Proof. by repeat split; try exists 0. Qed.
  Canonical Structure unitC : cofeT := CofeT unit unit_cofe_mixin.
  Global Instance unit_discrete_cofe : Discrete unitC.
  Proof. done. Qed.
End unit.

(** Product *)
Section product.
  Context {A B : cofeT}.

  Instance prod_dist : Dist (A * B) := λ n, prod_relation (dist n) (dist n).
  Global Instance pair_ne :
    Proper (dist n ==> dist n ==> dist n) (@pair A B) := _.
  Global Instance fst_ne : Proper (dist n ==> dist n) (@fst A B) := _.
  Global Instance snd_ne : Proper (dist n ==> dist n) (@snd A B) := _.
  Instance prod_compl : Compl (A * B) := λ c,
    (compl (chain_map fst c), compl (chain_map snd c)).
  Definition prod_cofe_mixin : CofeMixin (A * B).
  Proof.
    split.
    - intros x y; unfold dist, prod_dist, equiv, prod_equiv, prod_relation.
      rewrite !equiv_dist; naive_solver.
    - apply _.
    - by intros n [x1 y1] [x2 y2] [??]; split; apply dist_S.
    - intros n c; split. apply (conv_compl n (chain_map fst c)).
      apply (conv_compl n (chain_map snd c)).
  Qed.
  Canonical Structure prodC : cofeT := CofeT (A * B) prod_cofe_mixin.
  Global Instance prod_timeless (x : A * B) :
    Timeless (x.1) → Timeless (x.2) → Timeless x.
  Proof. by intros ???[??]; split; apply (timeless _). Qed.
  Global Instance prod_discrete_cofe : Discrete A → Discrete B → Discrete prodC.
  Proof. intros ?? [??]; apply _. Qed.
End product.

Arguments prodC : clear implicits.
Typeclasses Opaque prod_dist.

Instance prod_map_ne {A A' B B' : cofeT} n :
  Proper ((dist n ==> dist n) ==> (dist n ==> dist n) ==>
           dist n ==> dist n) (@prod_map A A' B B').
Proof. by intros f f' Hf g g' Hg ?? [??]; split; [apply Hf|apply Hg]. Qed.
Definition prodC_map {A A' B B'} (f : A -n> A') (g : B -n> B') :
  prodC A B -n> prodC A' B' := CofeMor (prod_map f g).
Instance prodC_map_ne {A A' B B'} n :
  Proper (dist n ==> dist n ==> dist n) (@prodC_map A A' B B').
Proof. intros f f' Hf g g' Hg [??]; split; [apply Hf|apply Hg]. Qed.

(** Functors *)
Structure cFunctor := CFunctor {
  cFunctor_car : cofeT → cofeT → cofeT;
  cFunctor_map {A1 A2 B1 B2} :
    ((A2 -n> A1) * (B1 -n> B2)) → cFunctor_car A1 B1 -n> cFunctor_car A2 B2;
  cFunctor_ne {A1 A2 B1 B2} n :
    Proper (dist n ==> dist n) (@cFunctor_map A1 A2 B1 B2);
  cFunctor_id {A B : cofeT} (x : cFunctor_car A B) :
    cFunctor_map (cid,cid) x ≡ x;
  cFunctor_compose {A1 A2 A3 B1 B2 B3}
      (f : A2 -n> A1) (g : A3 -n> A2) (f' : B1 -n> B2) (g' : B2 -n> B3) x :
    cFunctor_map (f◎g, g'◎f') x ≡ cFunctor_map (g,g') (cFunctor_map (f,f') x)
}.
Existing Instance cFunctor_ne.
Instance: Params (@cFunctor_map) 5.

Delimit Scope cFunctor_scope with CF.
Bind Scope cFunctor_scope with cFunctor.

Class cFunctorContractive (F : cFunctor) :=
  cFunctor_contractive A1 A2 B1 B2 :> Contractive (@cFunctor_map F A1 A2 B1 B2).

Definition cFunctor_diag (F: cFunctor) (A: cofeT) : cofeT := cFunctor_car F A A.
Coercion cFunctor_diag : cFunctor >-> Funclass.

Program Definition constCF (B : cofeT) : cFunctor :=
  {| cFunctor_car A1 A2 := B; cFunctor_map A1 A2 B1 B2 f := cid |}.
Solve Obligations with done.

Instance constCF_contractive B : cFunctorContractive (constCF B).
Proof. rewrite /cFunctorContractive; apply _. Qed.

Program Definition idCF : cFunctor :=
  {| cFunctor_car A1 A2 := A2; cFunctor_map A1 A2 B1 B2 f := f.2 |}.
Solve Obligations with done.

Program Definition prodCF (F1 F2 : cFunctor) : cFunctor := {|
  cFunctor_car A B := prodC (cFunctor_car F1 A B) (cFunctor_car F2 A B);
  cFunctor_map A1 A2 B1 B2 fg :=
    prodC_map (cFunctor_map F1 fg) (cFunctor_map F2 fg)
|}.
Next Obligation.
  intros ?? A1 A2 B1 B2 n ???; by apply prodC_map_ne; apply cFunctor_ne.
Qed.
Next Obligation. by intros F1 F2 A B [??]; rewrite /= !cFunctor_id. Qed.
Next Obligation.
  intros F1 F2 A1 A2 A3 B1 B2 B3 f g f' g' [??]; simpl.
  by rewrite !cFunctor_compose.
Qed.

Instance prodCF_contractive F1 F2 :
  cFunctorContractive F1 → cFunctorContractive F2 →
  cFunctorContractive (prodCF F1 F2).
Proof.
  intros ?? A1 A2 B1 B2 n ???;
    by apply prodC_map_ne; apply cFunctor_contractive.
Qed.

Instance compose_ne {A} {B B' : cofeT} (f : B -n> B') n :
  Proper (dist n ==> dist n) (compose f : (A -c> B) → A -c> B').
Proof. intros g g' Hf x; simpl. by rewrite (Hf x). Qed.

Definition cofe_funC_map {A B B'} (f : B -n> B') : (A -c> B) -n> (A -c> B') :=
  @CofeMor (_ -c> _) (_ -c> _) (compose f) _.
Instance cofe_funC_map_ne {A B B'} n :
  Proper (dist n ==> dist n) (@cofe_funC_map A B B').
Proof. intros f f' Hf g x. apply Hf. Qed.

Program Definition cofe_funCF (T : Type) (F : cFunctor) : cFunctor := {|
  cFunctor_car A B := cofe_funC T (cFunctor_car F A B);
  cFunctor_map A1 A2 B1 B2 fg := cofe_funC_map (cFunctor_map F fg)
|}.
Next Obligation.
  intros ?? A1 A2 B1 B2 n ???; by apply cofe_funC_map_ne; apply cFunctor_ne.
Qed.
Next Obligation. intros F1 F2 A B ??. by rewrite /= /compose /= !cFunctor_id. Qed.
Next Obligation.
  intros T F A1 A2 A3 B1 B2 B3 f g f' g' ??; simpl.
  by rewrite !cFunctor_compose.
Qed.

Instance cofe_funCF_contractive (T : Type) (F : cFunctor) :
  cFunctorContractive F → cFunctorContractive (cofe_funCF T F).
Proof.
  intros ?? A1 A2 B1 B2 n ???;
    by apply cofe_funC_map_ne; apply cFunctor_contractive.
Qed.

Program Definition cofe_morCF (F1 F2 : cFunctor) : cFunctor := {|
  cFunctor_car A B := cFunctor_car F1 B A -n> cFunctor_car F2 A B;
  cFunctor_map A1 A2 B1 B2 fg :=
    cofe_morC_map (cFunctor_map F1 (fg.2, fg.1)) (cFunctor_map F2 fg)
|}.
Next Obligation.
  intros F1 F2 A1 A2 B1 B2 n [f g] [f' g'] Hfg; simpl in *.
  apply cofe_morC_map_ne; apply cFunctor_ne; split; by apply Hfg.
Qed.
Next Obligation.
  intros F1 F2 A B [f ?] ?; simpl. rewrite /= !cFunctor_id.
  apply (ne_proper f). apply cFunctor_id.
Qed.
Next Obligation.
  intros F1 F2 A1 A2 A3 B1 B2 B3 f g f' g' [h ?] ?; simpl in *.
  rewrite -!cFunctor_compose. do 2 apply (ne_proper _). apply cFunctor_compose.
Qed.

Instance cofe_morCF_contractive F1 F2 :
  cFunctorContractive F1 → cFunctorContractive F2 →
  cFunctorContractive (cofe_morCF F1 F2).
Proof.
  intros ?? A1 A2 B1 B2 n [f g] [f' g'] Hfg; simpl in *.
  apply cofe_morC_map_ne; apply cFunctor_contractive=>i ?; split; by apply Hfg.
Qed.

(** Sum *)
Section sum.
  Context {A B : cofeT}.

  Instance sum_dist : Dist (A + B) := λ n, sum_relation (dist n) (dist n).
  Global Instance inl_ne : Proper (dist n ==> dist n) (@inl A B) := _.
  Global Instance inr_ne : Proper (dist n ==> dist n) (@inr A B) := _.
  Global Instance inl_ne_inj : Inj (dist n) (dist n) (@inl A B) := _.
  Global Instance inr_ne_inj : Inj (dist n) (dist n) (@inr A B) := _.

  Program Definition inl_chain (c : chain (A + B)) (a : A) : chain A :=
    {| chain_car n := match c n return _ with inl a' => a' | _ => a end |}.
  Next Obligation. intros c a n i ?; simpl. by destruct (chain_cauchy c n i). Qed.
  Program Definition inr_chain (c : chain (A + B)) (b : B) : chain B :=
    {| chain_car n := match c n return _ with inr b' => b' | _ => b end |}.
  Next Obligation. intros c b n i ?; simpl. by destruct (chain_cauchy c n i). Qed.

  Instance sum_compl : Compl (A + B) := λ c,
    match c 0 with
    | inl a => inl (compl (inl_chain c a))
    | inr b => inr (compl (inr_chain c b))
    end.

  Definition sum_cofe_mixin : CofeMixin (A + B).
  Proof.
    split.
    - intros x y; split=> Hx.
      + destruct Hx=> n; constructor; by apply equiv_dist.
      + destruct (Hx 0); constructor; apply equiv_dist=> n; by apply (inj _).
    - apply _.
    - destruct 1; constructor; by apply dist_S.
    - intros n c; rewrite /compl /sum_compl.
      feed inversion (chain_cauchy c 0 n); first auto with lia; constructor.
      + rewrite (conv_compl n (inl_chain c _)) /=. destruct (c n); naive_solver.
      + rewrite (conv_compl n (inr_chain c _)) /=. destruct (c n); naive_solver.
  Qed.
  Canonical Structure sumC : cofeT := CofeT (A + B) sum_cofe_mixin.

  Global Instance inl_timeless (x : A) : Timeless x → Timeless (inl x).
  Proof. inversion_clear 2; constructor; by apply (timeless _). Qed.
  Global Instance inr_timeless (y : B) : Timeless y → Timeless (inr y).
  Proof. inversion_clear 2; constructor; by apply (timeless _). Qed.
  Global Instance sum_discrete_cofe : Discrete A → Discrete B → Discrete sumC.
  Proof. intros ?? [?|?]; apply _. Qed.
End sum.

Arguments sumC : clear implicits.
Typeclasses Opaque sum_dist.

Instance sum_map_ne {A A' B B' : cofeT} n :
  Proper ((dist n ==> dist n) ==> (dist n ==> dist n) ==>
           dist n ==> dist n) (@sum_map A A' B B').
Proof.
  intros f f' Hf g g' Hg ??; destruct 1; constructor; [by apply Hf|by apply Hg].
Qed.
Definition sumC_map {A A' B B'} (f : A -n> A') (g : B -n> B') :
  sumC A B -n> sumC A' B' := CofeMor (sum_map f g).
Instance sumC_map_ne {A A' B B'} n :
  Proper (dist n ==> dist n ==> dist n) (@sumC_map A A' B B').
Proof. intros f f' Hf g g' Hg [?|?]; constructor; [apply Hf|apply Hg]. Qed.

Program Definition sumCF (F1 F2 : cFunctor) : cFunctor := {|
  cFunctor_car A B := sumC (cFunctor_car F1 A B) (cFunctor_car F2 A B);
  cFunctor_map A1 A2 B1 B2 fg :=
    sumC_map (cFunctor_map F1 fg) (cFunctor_map F2 fg)
|}.
Next Obligation.
  intros ?? A1 A2 B1 B2 n ???; by apply sumC_map_ne; apply cFunctor_ne.
Qed.
Next Obligation. by intros F1 F2 A B [?|?]; rewrite /= !cFunctor_id. Qed.
Next Obligation.
  intros F1 F2 A1 A2 A3 B1 B2 B3 f g f' g' [?|?]; simpl;
    by rewrite !cFunctor_compose.
Qed.

Instance sumCF_contractive F1 F2 :
  cFunctorContractive F1 → cFunctorContractive F2 →
  cFunctorContractive (sumCF F1 F2).
Proof.
  intros ?? A1 A2 B1 B2 n ???;
    by apply sumC_map_ne; apply cFunctor_contractive.
Qed.

(** Discrete cofe *)
Section discrete_cofe.
  Context `{Equiv A, @Equivalence A (≡)}.
  Instance discrete_dist : Dist A := λ n x y, x ≡ y.
  Instance discrete_compl : Compl A := λ c, c 0.
  Definition discrete_cofe_mixin : CofeMixin A.
  Proof.
    split.
    - intros x y; split; [done|intros Hn; apply (Hn 0)].
    - done.
    - done.
    - intros n c. rewrite /compl /discrete_compl /=;
      symmetry; apply (chain_cauchy c 0 n). omega.
  Qed.
End discrete_cofe.

Notation discreteC A := (CofeT A discrete_cofe_mixin).
Notation leibnizC A := (CofeT A (@discrete_cofe_mixin _ equivL _)).

Instance discrete_discrete_cofe `{Equiv A, @Equivalence A (≡)} :
  Discrete (discreteC A).
Proof. by intros x y. Qed.
Instance leibnizC_leibniz A : LeibnizEquiv (leibnizC A).
Proof. by intros x y. Qed.

Canonical Structure natC := leibnizC nat.
Canonical Structure boolC := leibnizC bool.

(* Option *)
Section option.
  Context {A : cofeT}.

  Instance option_dist : Dist (option A) := λ n, option_Forall2 (dist n).
  Lemma dist_option_Forall2 n mx my : mx ≡{n}≡ my ↔ option_Forall2 (dist n) mx my.
  Proof. done. Qed.

  Program Definition option_chain (c : chain (option A)) (x : A) : chain A :=
    {| chain_car n := from_option id x (c n) |}.
  Next Obligation. intros c x n i ?; simpl. by destruct (chain_cauchy c n i). Qed.
  Instance option_compl : Compl (option A) := λ c,
    match c 0 with Some x => Some (compl (option_chain c x)) | None => None end.

  Definition option_cofe_mixin : CofeMixin (option A).
  Proof.
    split.
    - intros mx my; split; [by destruct 1; constructor; apply equiv_dist|].
      intros Hxy; destruct (Hxy 0); constructor; apply equiv_dist.
      by intros n; feed inversion (Hxy n).
    - apply _.
    - destruct 1; constructor; by apply dist_S.
    - intros n c; rewrite /compl /option_compl.
      feed inversion (chain_cauchy c 0 n); first auto with lia; constructor.
      rewrite (conv_compl n (option_chain c _)) /=. destruct (c n); naive_solver.
  Qed.
  Canonical Structure optionC := CofeT (option A) option_cofe_mixin.
  Global Instance option_discrete : Discrete A → Discrete optionC.
  Proof. destruct 2; constructor; by apply (timeless _). Qed.

  Global Instance Some_ne : Proper (dist n ==> dist n) (@Some A).
  Proof. by constructor. Qed.
  Global Instance is_Some_ne n : Proper (dist n ==> iff) (@is_Some A).
  Proof. destruct 1; split; eauto. Qed.
  Global Instance Some_dist_inj : Inj (dist n) (dist n) (@Some A).
  Proof. by inversion_clear 1. Qed.
  Global Instance from_option_ne {B} (R : relation B) (f : A → B) n :
    Proper (dist n ==> R) f → Proper (R ==> dist n ==> R) (from_option f).
  Proof. destruct 3; simpl; auto. Qed.

  Global Instance None_timeless : Timeless (@None A).
  Proof. inversion_clear 1; constructor. Qed.
  Global Instance Some_timeless x : Timeless x → Timeless (Some x).
  Proof. by intros ?; inversion_clear 1; constructor; apply timeless. Qed.

  Lemma dist_None n mx : mx ≡{n}≡ None ↔ mx = None.
  Proof. split; [by inversion_clear 1|by intros ->]. Qed.
  Lemma dist_Some_inv_l n mx my x :
    mx ≡{n}≡ my → mx = Some x → ∃ y, my = Some y ∧ x ≡{n}≡ y.
  Proof. destruct 1; naive_solver. Qed.
  Lemma dist_Some_inv_r n mx my y :
    mx ≡{n}≡ my → my = Some y → ∃ x, mx = Some x ∧ x ≡{n}≡ y.
  Proof. destruct 1; naive_solver. Qed.
  Lemma dist_Some_inv_l' n my x : Some x ≡{n}≡ my → ∃ x', Some x' = my ∧ x ≡{n}≡ x'.
  Proof. intros ?%(dist_Some_inv_l _ _ _ x); naive_solver. Qed.
  Lemma dist_Some_inv_r' n mx y : mx ≡{n}≡ Some y → ∃ y', mx = Some y' ∧ y ≡{n}≡ y'.
  Proof. intros ?%(dist_Some_inv_r _ _ _ y); naive_solver. Qed.
End option.

Typeclasses Opaque option_dist.
Arguments optionC : clear implicits.

Instance option_fmap_ne {A B : cofeT} n:
  Proper ((dist n ==> dist n) ==> dist n ==> dist n) (@fmap option _ A B).
Proof. intros f f' Hf ?? []; constructor; auto. Qed.
Definition optionC_map {A B} (f : A -n> B) : optionC A -n> optionC B :=
  CofeMor (fmap f : optionC A → optionC B).
Instance optionC_map_ne A B n : Proper (dist n ==> dist n) (@optionC_map A B).
Proof. by intros f f' Hf []; constructor; apply Hf. Qed.

Program Definition optionCF (F : cFunctor) : cFunctor := {|
  cFunctor_car A B := optionC (cFunctor_car F A B);
  cFunctor_map A1 A2 B1 B2 fg := optionC_map (cFunctor_map F fg)
|}.
Next Obligation.
  by intros F A1 A2 B1 B2 n f g Hfg; apply optionC_map_ne, cFunctor_ne.
Qed.
Next Obligation.
  intros F A B x. rewrite /= -{2}(option_fmap_id x).
  apply option_fmap_setoid_ext=>y; apply cFunctor_id.
Qed.
Next Obligation.
  intros F A1 A2 A3 B1 B2 B3 f g f' g' x. rewrite /= -option_fmap_compose.
  apply option_fmap_setoid_ext=>y; apply cFunctor_compose.
Qed.

Instance optionCF_contractive F :
  cFunctorContractive F → cFunctorContractive (optionCF F).
Proof.
  by intros ? A1 A2 B1 B2 n f g Hfg; apply optionC_map_ne, cFunctor_contractive.
Qed.

(** Later *)
Inductive later (A : Type) : Type := Next { later_car : A }.
Add Printing Constructor later.
Arguments Next {_} _.
Arguments later_car {_} _.

Section later.
  Context {A : cofeT}.
  Instance later_equiv : Equiv (later A) := λ x y, later_car x ≡ later_car y.
  Instance later_dist : Dist (later A) := λ n x y,
    match n with 0 => True | S n => later_car x ≡{n}≡ later_car y end.
  Program Definition later_chain (c : chain (later A)) : chain A :=
    {| chain_car n := later_car (c (S n)) |}.
  Next Obligation. intros c n i ?; apply (chain_cauchy c (S n)); lia. Qed.
  Instance later_compl : Compl (later A) := λ c, Next (compl (later_chain c)).
  Definition later_cofe_mixin : CofeMixin (later A).
  Proof.
    split.
    - intros x y; unfold equiv, later_equiv; rewrite !equiv_dist.
      split. intros Hxy [|n]; [done|apply Hxy]. intros Hxy n; apply (Hxy (S n)).
    - intros [|n]; [by split|split]; unfold dist, later_dist.
      + by intros [x].
      + by intros [x] [y].
      + by intros [x] [y] [z] ??; trans y.
    - intros [|n] [x] [y] ?; [done|]; unfold dist, later_dist; by apply dist_S.
    - intros [|n] c; [done|by apply (conv_compl n (later_chain c))].
  Qed.
  Canonical Structure laterC : cofeT := CofeT (later A) later_cofe_mixin.
  Global Instance Next_contractive : Contractive (@Next A).
  Proof. intros [|n] x y Hxy; [done|]; apply Hxy; lia. Qed.
  Global Instance Later_inj n : Inj (dist n) (dist (S n)) (@Next A).
  Proof. by intros x y. Qed.
End later.

Arguments laterC : clear implicits.

Definition later_map {A B} (f : A → B) (x : later A) : later B :=
  Next (f (later_car x)).
Instance later_map_ne {A B : cofeT} (f : A → B) n :
  Proper (dist (pred n) ==> dist (pred n)) f →
  Proper (dist n ==> dist n) (later_map f) | 0.
Proof. destruct n as [|n]; intros Hf [x] [y] ?; do 2 red; simpl; auto. Qed.
Lemma later_map_id {A} (x : later A) : later_map id x = x.
Proof. by destruct x. Qed.
Lemma later_map_compose {A B C} (f : A → B) (g : B → C) (x : later A) :
  later_map (g ∘ f) x = later_map g (later_map f x).
Proof. by destruct x. Qed.
Lemma later_map_ext {A B : cofeT} (f g : A → B) x :
  (∀ x, f x ≡ g x) → later_map f x ≡ later_map g x.
Proof. destruct x; intros Hf; apply Hf. Qed.
Definition laterC_map {A B} (f : A -n> B) : laterC A -n> laterC B :=
  CofeMor (later_map f).
Instance laterC_map_contractive (A B : cofeT) : Contractive (@laterC_map A B).
Proof. intros [|n] f g Hf n'; [done|]; apply Hf; lia. Qed.

Program Definition laterCF (F : cFunctor) : cFunctor := {|
  cFunctor_car A B := laterC (cFunctor_car F A B);
  cFunctor_map A1 A2 B1 B2 fg := laterC_map (cFunctor_map F fg)
|}.
Next Obligation.
  intros F A1 A2 B1 B2 n fg fg' ?.
  by apply (contractive_ne laterC_map), cFunctor_ne.
Qed.
Next Obligation.
  intros F A B x; simpl. rewrite -{2}(later_map_id x).
  apply later_map_ext=>y. by rewrite cFunctor_id.
Qed.
Next Obligation.
  intros F A1 A2 A3 B1 B2 B3 f g f' g' x; simpl. rewrite -later_map_compose.
  apply later_map_ext=>y; apply cFunctor_compose.
Qed.

Instance laterCF_contractive F : cFunctorContractive (laterCF F).
Proof.
  intros A1 A2 B1 B2 n fg fg' Hfg.
  apply laterC_map_contractive => i ?. by apply cFunctor_ne, Hfg.
Qed.

(** Notation for writing functors *)
Notation "∙" := idCF : cFunctor_scope.
Notation "T -c> F" := (cofe_funCF T%type F%CF) : cFunctor_scope.
Notation "F1 -n> F2" := (cofe_morCF F1%CF F2%CF) : cFunctor_scope.
Notation "F1 * F2" := (prodCF F1%CF F2%CF) : cFunctor_scope.
Notation "F1 + F2" := (sumCF F1%CF F2%CF) : cFunctor_scope.
Notation "▶ F"  := (laterCF F%CF) (at level 20, right associativity) : cFunctor_scope.
Coercion constCF : cofeT >-> cFunctor.
