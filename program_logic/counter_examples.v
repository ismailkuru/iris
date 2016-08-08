From iris.algebra Require Import upred.
From iris.proofmode Require Import tactics.

(** This proves that we need the ▷ in a "Saved Proposition" construction with
name-dependent allocation. *)
Module savedprop. Section savedprop.
  Context (M : ucmraT).
  Notation iProp := (uPred M).
  Notation "¬ P" := (□ (P → False))%I : uPred_scope.
  Implicit Types P : iProp.

  (* Saved Propositions and view shifts. *)
  Context (sprop : Type) (saved : sprop → iProp → iProp).
  Hypothesis sprop_persistent : ∀ i P, PersistentP (saved i P).
  Hypothesis sprop_alloc_dep :
    ∀ (P : sprop → iProp), True =r=> (∃ i, saved i (P i)).
  Hypothesis sprop_agree : ∀ i P Q, saved i P ∧ saved i Q ⊢ P ↔ Q.

  (* Self-contradicting assertions are inconsistent *)
  Lemma no_self_contradiction P `{!PersistentP P} : □ (P ↔ ¬ P) ⊢ False.
  Proof.
    iIntros "#[H1 H2]".
    iAssert P as "#HP".
    { iApply "H2". iIntros "!# #HP". by iApply ("H1" with "[#]"). }
    by iApply ("H1" with "[#]").
  Qed.

  (* "Assertion with name [i]" is equivalent to any assertion P s.t. [saved i P] *)
  Definition A (i : sprop) : iProp := ∃ P, saved i P ★ □ P.
  Lemma saved_is_A i P `{!PersistentP P} : saved i P ⊢ □ (A i ↔ P).
  Proof.
    iIntros "#HS !#". iSplit.
    - iDestruct 1 as (Q) "[#HSQ HQ]".
      iApply (sprop_agree i P Q with "[]"); eauto.
    - iIntros "#HP". iExists P. by iSplit.
  Qed.

  (* Define [Q i] to be "negated assertion with name [i]". Show that this
     implies that assertion with name [i] is equivalent to its own negation. *)
  Definition Q i := saved i (¬ A i).
  Lemma Q_self_contradiction i : Q i ⊢ □ (A i ↔ ¬ A i).
  Proof. iIntros "#HQ !#". by iApply (saved_is_A i (¬A i)). Qed.

  (* We can obtain such a [Q i]. *)
  Lemma make_Q : True =r=> ∃ i, Q i.
  Proof. apply sprop_alloc_dep. Qed.

  (* Put together all the pieces to derive a contradiction. *)
  Lemma rvs_false : (True : uPred M) =r=> False.
  Proof.
    rewrite make_Q. apply uPred.rvs_mono. iDestruct 1 as (i) "HQ".
    iApply (no_self_contradiction (A i)). by iApply Q_self_contradiction.
  Qed.

  Lemma contradiction : False.
  Proof.
    apply (@uPred.adequacy M False 1); simpl.
    rewrite -uPred.later_intro. apply rvs_false.
  Qed.
End savedprop. End savedprop.

(** This proves that we need the ▷ when opening invariants. *)
(** We fork in [uPred M] for any M, but the proof would work in any BI. *)
Module inv. Section inv.
  Context (M : ucmraT).
  Notation iProp := (uPred M).
  Implicit Types P : iProp.

  (** Assumptions *)
  (* We have view shifts (two classes: empty/full mask) *)
  Inductive mask := M0 | M1.
  Context (pvs : mask → iProp → iProp).

  Hypothesis pvs_intro : ∀ E P, P ⊢ pvs E P.
  Hypothesis pvs_mono : ∀ E P Q, (P ⊢ Q) → pvs E P ⊢ pvs E Q.
  Hypothesis pvs_pvs : ∀ E P, pvs E (pvs E P) ⊢ pvs E P.
  Hypothesis pvs_frame_l : ∀ E P Q, P ★ pvs E Q ⊢ pvs E (P ★ Q).
  Hypothesis pvs_mask_mono : ∀ P, pvs M0 P ⊢ pvs M1 P.

  (* We have invariants *)
  Context (name : Type) (inv : name → iProp → iProp).
  Hypothesis inv_persistent : ∀ i P, PersistentP (inv i P).
  Hypothesis inv_alloc : ∀ P, P ⊢ pvs M1 (∃ i, inv i P).
  Hypothesis inv_open :
    ∀ i P Q R, (P ★ Q ⊢ pvs M0 (P ★ R)) → (inv i P ★ Q ⊢ pvs M1 R).

  (* We have tokens for a little "two-state STS": [start] -> [finish].
     state. [start] also asserts the exact state; it is only ever owned by the
     invariant.  [finished] is duplicable. *)
  (* Posssible implementations of these axioms:
     * Using the STS monoid of a two-state STS, where [start] is the
       authoritative saying the state is exactly [start], and [finish]
       is the "we are at least in state [finish]" typically owned by threads.
     * Ex () +_⊥ ()
  *)
  Context (gname : Type).
  Context (start finished : gname → iProp).

  Hypothesis sts_alloc : True ⊢ pvs M0 (∃ γ, start γ).
  Hypotheses start_finish : ∀ γ, start γ ⊢ pvs M0 (finished γ).

  Hypothesis finished_not_start : ∀ γ, start γ ★ finished γ ⊢ False.

  Hypothesis finished_dup : ∀ γ, finished γ ⊢ finished γ ★ finished γ.

  (* We assume that we cannot view shift to false. *)
  Hypothesis soundness : ¬ (True ⊢ pvs M1 False).

  (** Some general lemmas and proof mode compatibility. *)
  Lemma inv_open' i P R : inv i P ★ (P -★ pvs M0 (P ★ pvs M1 R)) ⊢ pvs M1 R.
  Proof.
    iIntros "(#HiP & HP)". iApply pvs_pvs. iApply inv_open; last first.
    { iSplit; first done. iExact "HP". }
    iIntros "(HP & HPw)". by iApply "HPw".
  Qed.

  Instance pvs_mono' E : Proper ((⊢) ==> (⊢)) (pvs E).
  Proof. intros P Q ?. by apply pvs_mono. Qed.
  Instance pvs_proper E : Proper ((⊣⊢) ==> (⊣⊢)) (pvs E).
  Proof.
    intros P Q; rewrite !uPred.equiv_spec=> -[??]; split; by apply pvs_mono.
  Qed.

  Lemma pvs_frame_r E P Q : (pvs E P ★ Q) ⊢ pvs E (P ★ Q).
  Proof. by rewrite comm pvs_frame_l comm. Qed.

  Global Instance elim_pvs_pvs E P Q : ElimVs (pvs E P) P (pvs E Q) (pvs E Q).
  Proof. by rewrite /ElimVs pvs_frame_r uPred.wand_elim_r pvs_pvs. Qed.

  Global Instance elim_pvs0_pvs1 P Q : ElimVs (pvs M0 P) P (pvs M1 Q) (pvs M1 Q).
  Proof.
    by rewrite /ElimVs pvs_frame_r uPred.wand_elim_r pvs_mask_mono pvs_pvs.
  Qed.

  Global Instance exists_split_pvs0 {A} E P (Φ : A → iProp) :
    FromExist P Φ → FromExist (pvs E P) (λ a, pvs E (Φ a)).
  Proof.
    rewrite /FromExist=>HP. apply uPred.exist_elim=> a.
    apply pvs_mono. by rewrite -HP -(uPred.exist_intro a).
  Qed.

  (** Now to the actual counterexample. We start with a weird form of saved propositions. *)
  Definition saved (γ : gname) (P : iProp) : iProp :=
    ∃ i, inv i (start γ ∨ (finished γ ★ □ P)).
  Global Instance saved_persistent γ P : PersistentP (saved γ P) := _.

  Lemma saved_alloc (P : gname → iProp) : True ⊢ pvs M1 (∃ γ, saved γ (P γ)).
  Proof.
    iIntros "". iVs (sts_alloc) as (γ) "Hs".
    iVs (inv_alloc (start γ ∨ (finished γ ★ □ (P γ))) with "[Hs]") as (i) "#Hi".
    { auto. }
    iApply pvs_intro. by iExists γ, i.
  Qed.

  Lemma saved_cast γ P Q : saved γ P ★ saved γ Q ★ □ P ⊢ pvs M1 (□ Q).
  Proof.
    iIntros "(#HsP & #HsQ & #HP)". iDestruct "HsP" as (i) "HiP".
    iApply (inv_open' i). iSplit; first done.
    iIntros "HaP". iAssert (pvs M0 (finished γ)) with "[HaP]" as "==> Hf".
    { iDestruct "HaP" as "[Hs | [Hf _]]".
      - by iApply start_finish.
      - by iApply pvs_intro. }
    iDestruct (finished_dup with "Hf") as "[Hf Hf']".
    iApply pvs_intro. iSplitL "Hf'"; first by eauto.
    (* Step 2: Open the Q-invariant. *)
    iClear "HiP". clear i. iDestruct "HsQ" as (i) "HiQ".
    iApply (inv_open' i). iSplit; first done.
    iIntros "[HaQ | [_ #HQ]]".
    { iExFalso. iApply finished_not_start. by iFrame. }
    iApply pvs_intro. iSplitL "Hf".
    { iRight. by iFrame. }
    by iApply pvs_intro.
  Qed.

  (** And now we tie a bad knot. *)
  Notation "¬ P" := (□ (P -★ pvs M1 False))%I : uPred_scope.
  Definition A i : iProp := ∃ P, ¬P ★ saved i P.
  Global Instance A_persistent i : PersistentP (A i) := _.

  Lemma A_alloc : True ⊢ pvs M1 (∃ i, saved i (A i)).
  Proof. by apply saved_alloc. Qed.

  Lemma alloc_NA i : saved i (A i) ⊢ ¬A i.
  Proof.
    iIntros "#Hi !# #HA". iPoseProof "HA" as "HA'".
    iDestruct "HA'" as (P) "#[HNP Hi']".
    iVs (saved_cast i with "[]") as "HP".
    { iSplit; first iExact "Hi". by iFrame "#". }
    by iApply "HNP".
  Qed.

  Lemma alloc_A i : saved i (A i) ⊢ A i.
  Proof.
    iIntros "#Hi". iPoseProof (alloc_NA with "Hi") as "HNA".
    iExists (A i). by iFrame "#".
  Qed.

  Lemma contradiction : False.
  Proof.
    apply soundness. iIntros "".
    iVs A_alloc as (i) "#H".
    iPoseProof (alloc_NA with "H") as "HN".
    iApply "HN". iApply alloc_A. done.
  Qed.
End inv. End inv.
