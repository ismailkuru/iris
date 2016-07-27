From iris.algebra Require Export cmra.
From iris.prelude Require Export list.
From iris.algebra Require Import upred updates local_updates.

Section cofe.
Context {A : cofeT}.

Instance list_dist : Dist (list A) := λ n, Forall2 (dist n).

Lemma list_dist_lookup n l1 l2 : l1 ≡{n}≡ l2 ↔ ∀ i, l1 !! i ≡{n}≡ l2 !! i.
Proof. setoid_rewrite dist_option_Forall2. apply Forall2_lookup. Qed.

Global Instance cons_ne n : Proper (dist n ==> dist n ==> dist n) (@cons A) := _.
Global Instance app_ne n : Proper (dist n ==> dist n ==> dist n) (@app A) := _.
Global Instance length_ne n : Proper (dist n ==> (=)) (@length A) := _.
Global Instance tail_ne n : Proper (dist n ==> dist n) (@tail A) := _.
Global Instance take_ne n : Proper (dist n ==> dist n) (@take A n) := _.
Global Instance drop_ne n : Proper (dist n ==> dist n) (@drop A n) := _.
Global Instance list_lookup_ne n i :
  Proper (dist n ==> dist n) (lookup (M:=list) i).
Proof. intros ???. by apply dist_option_Forall2, Forall2_lookup. Qed.
Global Instance list_alter_ne n f i :
  Proper (dist n ==> dist n) f →
  Proper (dist n ==> dist n) (alter (M:=list) f i) := _.
Global Instance list_insert_ne n i :
  Proper (dist n ==> dist n ==> dist n) (insert (M:=list) i) := _.
Global Instance list_inserts_ne n i :
  Proper (dist n ==> dist n ==> dist n) (@list_inserts A i) := _.
Global Instance list_delete_ne n i :
  Proper (dist n ==> dist n) (delete (M:=list) i) := _.
Global Instance option_list_ne n : Proper (dist n ==> dist n) (@option_list A).
Proof. intros ???; by apply Forall2_option_list, dist_option_Forall2. Qed.
Global Instance list_filter_ne n P `{∀ x, Decision (P x)} :
  Proper (dist n ==> iff) P →
  Proper (dist n ==> dist n) (filter (B:=list A) P) := _.
Global Instance replicate_ne n :
  Proper (dist n ==> dist n) (@replicate A n) := _.
Global Instance reverse_ne n : Proper (dist n ==> dist n) (@reverse A) := _.
Global Instance last_ne n : Proper (dist n ==> dist n) (@last A).
Proof. intros ???; by apply dist_option_Forall2, Forall2_last. Qed.
Global Instance resize_ne n :
  Proper (dist n ==> dist n ==> dist n) (@resize A n) := _.

Program Definition list_chain
    (c : chain (list A)) (x : A) (k : nat) : chain A :=
  {| chain_car n := from_option id x (c n !! k) |}.
Next Obligation. intros c x k n i ?. by rewrite /= (chain_cauchy c n i). Qed.
Instance list_compl : Compl (list A) := λ c,
  match c 0 with
  | [] => []
  | x :: _ => compl ∘ list_chain c x <$> seq 0 (length (c 0))
  end.

Definition list_cofe_mixin : CofeMixin (list A).
Proof.
  split.
  - intros l k. rewrite equiv_Forall2 -Forall2_forall.
    split; induction 1; constructor; intros; try apply equiv_dist; auto.
  - apply _.
  - rewrite /dist /list_dist. eauto using Forall2_impl, dist_S.
  - intros n c; rewrite /compl /list_compl.
    destruct (c 0) as [|x l] eqn:Hc0 at 1.
    { by destruct (chain_cauchy c 0 n); auto with omega. }
    rewrite -(λ H, length_ne _ _ _ (chain_cauchy c 0 n H)); last omega.
    apply Forall2_lookup=> i. rewrite -dist_option_Forall2 list_lookup_fmap.
    destruct (decide (i < length (c n))); last first.
    { rewrite lookup_seq_ge ?lookup_ge_None_2; auto with omega. }
    rewrite lookup_seq //= (conv_compl n (list_chain c _ _)) /=.
    by destruct (lookup_lt_is_Some_2 (c n) i) as [? ->].
Qed.
Canonical Structure listC := CofeT (list A) list_cofe_mixin.
Global Instance list_discrete : Discrete A → Discrete listC.
Proof. induction 2; constructor; try apply (timeless _); auto. Qed.

Global Instance nil_timeless : Timeless (@nil A).
Proof. inversion_clear 1; constructor. Qed.
Global Instance cons_timeless x l : Timeless x → Timeless l → Timeless (x :: l).
Proof. intros ??; inversion_clear 1; constructor; by apply timeless. Qed.
End cofe.

Arguments listC : clear implicits.

(** Functor *)
Instance list_fmap_ne {A B : cofeT} (f : A → B) n:
  Proper (dist n ==> dist n) f → Proper (dist n ==> dist n) (fmap (M:=list) f).
Proof. intros Hf l k ?; by eapply Forall2_fmap, Forall2_impl; eauto. Qed. 
Definition listC_map {A B} (f : A -n> B) : listC A -n> listC B :=
  CofeMor (fmap f : listC A → listC B).
Instance listC_map_ne A B n : Proper (dist n ==> dist n) (@listC_map A B).
Proof. intros f f' ? l; by apply Forall2_fmap, Forall_Forall2, Forall_true. Qed.

Program Definition listCF (F : cFunctor) : cFunctor := {|
  cFunctor_car A B := listC (cFunctor_car F A B);
  cFunctor_map A1 A2 B1 B2 fg := listC_map (cFunctor_map F fg)
|}.
Next Obligation.
  by intros F A1 A2 B1 B2 n f g Hfg; apply listC_map_ne, cFunctor_ne.
Qed.
Next Obligation.
  intros F A B x. rewrite /= -{2}(list_fmap_id x).
  apply list_fmap_setoid_ext=>y. apply cFunctor_id.
Qed.
Next Obligation.
  intros F A1 A2 A3 B1 B2 B3 f g f' g' x. rewrite /= -list_fmap_compose.
  apply list_fmap_setoid_ext=>y; apply cFunctor_compose.
Qed.

Instance listCF_contractive F :
  cFunctorContractive F → cFunctorContractive (listCF F).
Proof.
  by intros ? A1 A2 B1 B2 n f g Hfg; apply listC_map_ne, cFunctor_contractive.
Qed.

(* CMRA *)
Section cmra.
  Context {A : ucmraT}.
  Implicit Types l : list A.
  Local Arguments op _ _ !_ !_ / : simpl nomatch.

  Instance list_op : Op (list A) :=
    fix go l1 l2 := let _ : Op _ := @go in
    match l1, l2 with
    | [], _ => l2
    | _, [] => l1
    | x :: l1, y :: l2 => x ⋅ y :: l1 ⋅ l2
    end.
  Instance list_pcore : PCore (list A) := λ l, Some (core <$> l).

  Instance list_valid : Valid (list A) := Forall (λ x, ✓ x).
  Instance list_validN : ValidN (list A) := λ n, Forall (λ x, ✓{n} x).

  Lemma list_lookup_valid l : ✓ l ↔ ∀ i, ✓ (l !! i).
  Proof.
    rewrite {1}/valid /list_valid Forall_lookup; split.
    - intros Hl i. by destruct (l !! i) as [x|] eqn:?; [apply (Hl i)|].
    - intros Hl i x Hi. move: (Hl i); by rewrite Hi.
  Qed.
  Lemma list_lookup_validN n l : ✓{n} l ↔ ∀ i, ✓{n} (l !! i).
  Proof.
    rewrite {1}/validN /list_validN Forall_lookup; split.
    - intros Hl i. by destruct (l !! i) as [x|] eqn:?; [apply (Hl i)|].
    - intros Hl i x Hi. move: (Hl i); by rewrite Hi.
  Qed.
  Lemma list_lookup_op l1 l2 i : (l1 ⋅ l2) !! i = l1 !! i ⋅ l2 !! i.
  Proof.
    revert i l2. induction l1 as [|x l1]; intros [|i] [|y l2];
      by rewrite /= ?left_id_L ?right_id_L.
  Qed.
  Lemma list_lookup_core l i : core l !! i = core (l !! i).
  Proof.
    rewrite /core /= list_lookup_fmap.
    destruct (l !! i); by rewrite /= ?Some_core.
  Qed.

  Lemma list_lookup_included l1 l2 : l1 ≼ l2 ↔ ∀ i, l1 !! i ≼ l2 !! i.
  Proof.
    split.
    { intros [l Hl] i. exists (l !! i). by rewrite Hl list_lookup_op. }
    revert l1. induction l2 as [|y l2 IH]=>-[|x l1] Hl.
    - by exists [].
    - destruct (Hl 0) as [[z|] Hz]; inversion Hz.
    - by exists (y :: l2).
    - destruct (IH l1) as [l3 ?]; first (intros i; apply (Hl (S i))).
      destruct (Hl 0) as [[z|] Hz]; inversion_clear Hz; simplify_eq/=.
      + exists (z :: l3); by constructor.
      + exists (core x :: l3); constructor; by rewrite ?cmra_core_r.
  Qed.

  Definition list_cmra_mixin : CMRAMixin (list A).
  Proof.
    apply cmra_total_mixin.
    - eauto.
    - intros n l l1 l2; rewrite !list_dist_lookup=> Hl i.
      by rewrite !list_lookup_op Hl.
    - intros n l1 l2 Hl; by rewrite /core /= Hl.
    - intros n l1 l2; rewrite !list_dist_lookup !list_lookup_validN=> Hl ? i.
      by rewrite -Hl.
    - intros l. rewrite list_lookup_valid. setoid_rewrite list_lookup_validN.
      setoid_rewrite cmra_valid_validN. naive_solver.
    - intros n x. rewrite !list_lookup_validN. auto using cmra_validN_S.
    - intros l1 l2 l3; rewrite list_equiv_lookup=> i.
      by rewrite !list_lookup_op assoc.
    - intros l1 l2; rewrite list_equiv_lookup=> i.
      by rewrite !list_lookup_op comm.
    - intros l; rewrite list_equiv_lookup=> i.
      by rewrite list_lookup_op list_lookup_core cmra_core_l.
    - intros l; rewrite list_equiv_lookup=> i.
      by rewrite !list_lookup_core cmra_core_idemp.
    - intros l1 l2; rewrite !list_lookup_included=> Hl i.
      rewrite !list_lookup_core. by apply cmra_core_mono.
    - intros n l1 l2. rewrite !list_lookup_validN.
      setoid_rewrite list_lookup_op. eauto using cmra_validN_op_l.
    - intros n l. induction l as [|x l IH]=> -[|y1 l1] [|y2 l2] Hl Hl';
        try (by exfalso; inversion_clear Hl').
      + by exists ([], []).
      + by exists ([], x :: l).
      + by exists (x :: l, []).
      + destruct (IH l1 l2) as ([l1' l2']&?&?&?),
          (cmra_extend n x y1 y2) as ([y1' y2']&?&?&?);
          [inversion_clear Hl; inversion_clear Hl'; auto ..|]; simplify_eq/=.
        exists (y1' :: l1', y2' :: l2'); repeat constructor; auto.
  Qed.
  Canonical Structure listR := CMRAT (list A) list_cofe_mixin list_cmra_mixin.

  Global Instance empty_list : Empty (list A) := [].
  Definition list_ucmra_mixin : UCMRAMixin (list A).
  Proof.
    split.
    - constructor.
    - by intros l.
    - by inversion_clear 1.
    - by constructor.
  Qed.
  Canonical Structure listUR :=
    UCMRAT (list A) list_cofe_mixin list_cmra_mixin list_ucmra_mixin.

  Global Instance list_cmra_discrete : CMRADiscrete A → CMRADiscrete listR.
  Proof.
    split; [apply _|]=> l; rewrite list_lookup_valid list_lookup_validN=> Hl i.
    by apply cmra_discrete_valid.
  Qed.

  Global Instance list_persistent l : (∀ x : A, Persistent x) → Persistent l.
  Proof.
    intros ?; constructor; apply list_equiv_lookup=> i.
    by rewrite list_lookup_core (persistent_core (l !! i)).
  Qed.

  (** Internalized properties *)
  Lemma list_equivI {M} l1 l2 : l1 ≡ l2 ⊣⊢ (∀ i, l1 !! i ≡ l2 !! i : uPred M).
  Proof. uPred.unseal; constructor=> n x ?. apply list_dist_lookup. Qed.
  Lemma list_validI {M} l : ✓ l ⊣⊢ (∀ i, ✓ (l !! i) : uPred M).
  Proof. uPred.unseal; constructor=> n x ?. apply list_lookup_validN. Qed.
End cmra.

Arguments listR : clear implicits.
Arguments listUR : clear implicits.

Definition list_singleton {A : ucmraT} (n : nat) (x : A) : list A :=
  replicate n ∅ ++ [x].

Section properties.
  Context {A : ucmraT}.
  Implicit Types l k : list A.
  Implicit Types ml mk : option (list A).
  Implicit Types x y z : A.
  Implicit Types i : nat.
  Local Arguments op _ _ !_ !_ / : simpl nomatch.
  Local Arguments cmra_op _ !_ !_ / : simpl nomatch.

  Lemma list_lookup_opM l mk i :
    (l ⋅? mk) !! i = l !! i ⋅ (mk ≫= (!! i) : option A).
  Proof. destruct mk; by rewrite /= ?list_lookup_op ?right_id_L. Qed.

  Lemma list_op_app l1 l2 l3 :
    length l2 ≤ length l1 → (l1 ++ l3) ⋅ l2 = (l1 ⋅ l2) ++ l3.
  Proof.
    revert l2 l3.
    induction l1 as [|x1 l1]=> -[|x2 l2] [|x3 l3] ?; f_equal/=; auto with lia.
  Qed.

  Lemma list_lookup_validN_Some n l i x : ✓{n} l → l !! i ≡{n}≡ Some x → ✓{n} x.
  Proof. move=> /list_lookup_validN /(_ i)=> Hl Hi; move: Hl. by rewrite Hi. Qed.
  Lemma list_lookup_valid_Some l i x : ✓ l → l !! i ≡ Some x → ✓ x.
  Proof. move=> /list_lookup_valid /(_ i)=> Hl Hi; move: Hl. by rewrite Hi. Qed.

  Lemma list_op_length l1 l2 : length (l1 ⋅ l2) = max (length l1) (length l2).
  Proof. revert l2. induction l1; intros [|??]; f_equal/=; auto. Qed.

  Lemma replicate_valid n (x : A) : ✓ x → ✓ replicate n x.
  Proof. apply Forall_replicate. Qed.
  Global Instance list_singleton_ne n i :
    Proper (dist n ==> dist n) (@list_singleton A i).
  Proof. intros l1 l2 ?. apply Forall2_app; by repeat constructor. Qed.
  Global Instance list_singleton_proper i :
    Proper ((≡) ==> (≡)) (list_singleton i) := ne_proper _.

  Lemma elem_of_list_singleton i z x : z ∈ list_singleton i x → z = ∅ ∨ z = x.
  Proof.
    rewrite elem_of_app elem_of_list_singleton elem_of_replicate. naive_solver.
  Qed.
  Lemma list_lookup_singleton i x : list_singleton i x !! i = Some x.
  Proof. induction i; by f_equal/=. Qed.
  Lemma list_lookup_singleton_ne i j x :
    i ≠ j → list_singleton i x !! j = None ∨ list_singleton i x !! j = Some ∅.
  Proof. revert j; induction i; intros [|j]; naive_solver auto with omega. Qed.
  Lemma list_singleton_validN n i x : ✓{n} (list_singleton i x) ↔ ✓{n} x.
  Proof.
    rewrite list_lookup_validN. split.
    { move=> /(_ i). by rewrite list_lookup_singleton. }
    intros Hx j; destruct (decide (i = j)); subst.
    - by rewrite list_lookup_singleton.
    - destruct (list_lookup_singleton_ne i j x) as [Hi|Hi]; first done;
        rewrite Hi; by try apply (ucmra_unit_validN (A:=A)).
  Qed.
  Lemma list_singleton_valid  i x : ✓ (list_singleton i x) ↔ ✓ x.
  Proof.
    rewrite !cmra_valid_validN. by setoid_rewrite list_singleton_validN.
  Qed.
  Lemma list_singleton_length i x : length (list_singleton i x) = S i.
  Proof. rewrite /list_singleton app_length replicate_length /=; lia. Qed.

  Lemma list_core_singleton i x :
    core (list_singleton i x) ≡ list_singleton i (core x).
  Proof.
    rewrite /list_singleton.
    by rewrite {1}/core /= fmap_app fmap_replicate (persistent_core ∅).
  Qed.
  Lemma list_op_singleton i x y :
    list_singleton i x ⋅ list_singleton i y ≡ list_singleton i (x ⋅ y).
  Proof. induction i; constructor; rewrite ?left_id; auto. Qed.
  Lemma list_alter_singleton f i x :
    alter f i (list_singleton i x) = list_singleton i (f x).
  Proof. rewrite /list_singleton. induction i; f_equal/=; auto. Qed.
  Global Instance list_singleton_persistent i x :
    Persistent x → Persistent (list_singleton i x).
  Proof. by rewrite !persistent_total list_core_singleton=> ->. Qed.

  (* Update *)
  Lemma list_middle_updateP (P : A → Prop) (Q : list A → Prop) l1 x l2 :
    x ~~>: P → (∀ y, P y → Q (l1 ++ y :: l2)) → l1 ++ x :: l2 ~~>: Q.
  Proof.
    intros Hx%option_updateP' HP.
    apply cmra_total_updateP=> n mf; rewrite list_lookup_validN=> Hm.
    destruct (Hx n (Some (mf !! length l1))) as ([y|]&H1&H2); simpl in *; try done.
    { move: (Hm (length l1)). by rewrite list_lookup_op list_lookup_middle. }
    exists (l1 ++ y :: l2); split; auto.
    apply list_lookup_validN=> i.
    destruct (lt_eq_lt_dec i (length l1)) as [[?|?]|?]; subst.
    - move: (Hm i); by rewrite !list_lookup_op !lookup_app_l.
    - by rewrite list_lookup_op list_lookup_middle.
    - move: (Hm i). rewrite !(cons_middle _ l1 l2) !assoc.
      rewrite !list_lookup_op !lookup_app_r !app_length //=; lia.
  Qed.

  Lemma list_middle_update l1 l2 x y : x ~~> y → l1 ++ x :: l2 ~~> l1 ++ y :: l2.
  Proof.
    rewrite !cmra_update_updateP => H; eauto using list_middle_updateP with subst.
  Qed.

  Lemma list_middle_local_update l1 l2 x y ml :
    x ~l~> y @ ml ≫= (!! length l1) →
    l1 ++ x :: l2 ~l~> l1 ++ y :: l2 @ ml.
  Proof.
    intros [Hxy Hxy']; split.
    - intros n; rewrite !list_lookup_validN=> Hl i; move: (Hl i).
      destruct (lt_eq_lt_dec i (length l1)) as [[?|?]|?]; subst.
      + by rewrite !list_lookup_opM !lookup_app_l.
      + rewrite !list_lookup_opM !list_lookup_middle // !Some_op_opM; apply (Hxy n).
      + rewrite !(cons_middle _ l1 l2) !assoc.
        rewrite !list_lookup_opM !lookup_app_r !app_length //=; lia.
    - intros n mk; rewrite !list_lookup_validN !list_dist_lookup => Hl Hl' i.
      move: (Hl i) (Hl' i).
      destruct (lt_eq_lt_dec i (length l1)) as [[?|?]|?]; subst.
      + by rewrite !list_lookup_opM !lookup_app_l.
      + rewrite !list_lookup_opM !list_lookup_middle // !Some_op_opM !inj_iff.
        apply (Hxy' n).
      + rewrite !(cons_middle _ l1 l2) !assoc.
        rewrite !list_lookup_opM !lookup_app_r !app_length //=; lia.
  Qed.

  Lemma list_singleton_local_update i x y ml :
    x ~l~> y @ ml ≫= (!! i) → list_singleton i x ~l~> list_singleton i y @ ml.
  Proof. intros; apply list_middle_local_update. by rewrite replicate_length. Qed.
End properties.

(** Functor *)
Instance list_fmap_cmra_monotone {A B : ucmraT} (f : A → B)
  `{!CMRAMonotone f} : CMRAMonotone (fmap f : list A → list B).
Proof.
  split; try apply _.
  - intros n l. rewrite !list_lookup_validN=> Hl i. rewrite list_lookup_fmap.
    by apply (validN_preserving (fmap f : option A → option B)).
  - intros l1 l2. rewrite !list_lookup_included=> Hl i. rewrite !list_lookup_fmap.
    by apply (cmra_monotone (fmap f : option A → option B)).
Qed.

Program Definition listURF (F : urFunctor) : urFunctor := {|
  urFunctor_car A B := listUR (urFunctor_car F A B);
  urFunctor_map A1 A2 B1 B2 fg := listC_map (urFunctor_map F fg)
|}.
Next Obligation.
  by intros F ???? n f g Hfg; apply listC_map_ne, urFunctor_ne.
Qed.
Next Obligation.
  intros F A B x. rewrite /= -{2}(list_fmap_id x).
  apply list_fmap_setoid_ext=>y. apply urFunctor_id.
Qed.
Next Obligation.
  intros F A1 A2 A3 B1 B2 B3 f g f' g' x. rewrite /= -list_fmap_compose.
  apply list_fmap_setoid_ext=>y; apply urFunctor_compose.
Qed.

Instance listURF_contractive F :
  urFunctorContractive F → urFunctorContractive (listURF F).
Proof.
  by intros ? A1 A2 B1 B2 n f g Hfg; apply listC_map_ne, urFunctor_contractive.
Qed.
