From iris.program_logic Require Export weakestpre.
From iris.heap_lang Require Export lang.
From iris.proofmode Require Import tactics.
From iris.heap_lang Require Import proofmode notation.
From iris.algebra Require Import excl.

Definition spawn : val :=
  λ: "f",
    let: "c" := ref NONE in
    Fork ("c" <- SOME ("f" #())) ;; "c".
Definition join : val :=
  rec: "join" "c" :=
    match: !"c" with
      SOME "x" => "x"
    | NONE => "join" "c"
    end.
Global Opaque spawn join.

(** The CMRA & functor we need. *)
(* Not bundling heapG, as it may be shared with other users. *)
Class spawnG Σ := SpawnG { spawn_tokG :> inG Σ (exclR unitC) }.
Definition spawnΣ : gFunctors := #[GFunctor (constRF (exclR unitC))].

Instance subG_spawnΣ {Σ} : subG spawnΣ Σ → spawnG Σ.
Proof. intros [?%subG_inG _]%subG_inv. split; apply _. Qed.

(** Now we come to the Iris part of the proof. *)
Section proof.
Context `{!heapG Σ, !spawnG Σ} (N : namespace).

Definition spawn_inv (γ : gname) (l : loc) (Ψ : val → iProp Σ) : iProp Σ :=
  (∃ lv, l ↦ lv ∗ (lv = NONEV ∨
                   ∃ v, lv = SOMEV v ∗ (Ψ v ∨ own γ (Excl ()))))%I.

Definition join_handle (l : loc) (Ψ : val → iProp Σ) : iProp Σ :=
  (heapN ⊥ N ∗ ∃ γ, heap_ctx ∗ own γ (Excl ()) ∗
                    inv N (spawn_inv γ l Ψ))%I.

Typeclasses Opaque join_handle.

Global Instance spawn_inv_ne n γ l :
  Proper (pointwise_relation val (dist n) ==> dist n) (spawn_inv γ l).
Proof. solve_proper. Qed.
Global Instance join_handle_ne n l :
  Proper (pointwise_relation val (dist n) ==> dist n) (join_handle l).
Proof. solve_proper. Qed.

(** The main proofs. *)
Lemma spawn_spec (Ψ : val → iProp Σ) e (f : val) :
  to_val e = Some f →
  heapN ⊥ N →
  {{{ heap_ctx ∗ WP f #() {{ Ψ }} }}} spawn e {{{ l, RET #l; join_handle l Ψ }}}.
Proof.
  iIntros (<-%of_to_val ? Φ) "(#Hh & Hf) HΦ". rewrite /spawn /=.
  wp_let. wp_alloc l as "Hl". wp_let.
  iMod (own_alloc (Excl ())) as (γ) "Hγ"; first done.
  iMod (inv_alloc N _ (spawn_inv γ l Ψ) with "[Hl]") as "#?".
  { iNext. iExists NONEV. iFrame; eauto. }
  wp_apply wp_fork; simpl. iSplitR "Hf".
  - wp_seq. iApply "HΦ". rewrite /join_handle. eauto.
  - wp_bind (f _). iApply (wp_wand with "Hf"); iIntros (v) "Hv".
    iInv N as (v') "[Hl _]" "Hclose".
    wp_store. iApply "Hclose". iNext. iExists (SOMEV v). iFrame. eauto.
Qed.

Lemma join_spec (Ψ : val → iProp Σ) l :
  {{{ join_handle l Ψ }}} join #l {{{ v, RET v; Ψ v }}}.
Proof.
  rewrite /join_handle; iIntros (Φ) "[% H] HΦ". iDestruct "H" as (γ) "(#?&Hγ&#?)".
  iLöb as "IH". wp_rec. wp_bind (! _)%E. iInv N as (v) "[Hl Hinv]" "Hclose".
  wp_load. iDestruct "Hinv" as "[%|Hinv]"; subst.
  - iMod ("Hclose" with "[Hl]"); [iNext; iExists _; iFrame; eauto|].
    iModIntro. wp_match. iApply ("IH" with "Hγ [HΦ]"). auto.
  - iDestruct "Hinv" as (v') "[% [HΨ|Hγ']]"; simplify_eq/=.
    + iMod ("Hclose" with "[Hl Hγ]"); [iNext; iExists _; iFrame; eauto|].
      iModIntro. wp_match. by iApply "HΦ".
    + iCombine "Hγ" "Hγ'" as "Hγ". iDestruct (own_valid with "Hγ") as %[].
Qed.
End proof.

Typeclasses Opaque join_handle.
