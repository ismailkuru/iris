From iris.program_logic Require Export weakestpre.
From iris.algebra Require Import gmap auth agree gset coPset upred_big_op.
From iris.program_logic Require Import ownership.
From iris.proofmode Require Import tactics weakestpre.
Import uPred.

Section adequacy.
Context `{irisG Λ Σ}.
Implicit Types e : expr Λ.
Implicit Types P Q : iProp Σ.
Implicit Types Φ : val Λ → iProp Σ.
Implicit Types Φs : list (val Λ → iProp Σ).

Notation world σ := (wsat ★ ownE ⊤ ★ ownP_auth σ)%I.

Definition wptp (t : list (expr Λ)) := ([★] (flip (wp ⊤) (λ _, True) <$> t))%I.

Lemma wptp_cons e t : wptp (e :: t) ⊣⊢ WP e {{ _, True }} ★ wptp t.
Proof. done. Qed.
Lemma wptp_app t1 t2 : wptp (t1 ++ t2) ⊣⊢ wptp t1 ★ wptp t2.
Proof. by rewrite /wptp fmap_app big_sep_app. Qed.
Lemma wptp_fork ef : wptp (option_list ef) ⊣⊢ wp_fork ef.
Proof. destruct ef; by rewrite /wptp /= ?right_id. Qed.

Lemma wp_step e1 σ1 e2 σ2 ef Φ :
  prim_step e1 σ1 e2 σ2 ef →
  world σ1 ★ WP e1 {{ Φ }} =r=> ▷ |=r=> ◇ (world σ2 ★ WP e2 {{ Φ }} ★ wp_fork ef).
Proof.
  rewrite {1}wp_unfold /wp_pre. iIntros (Hstep) "[(Hw & HE & Hσ) [H|[_ H]]]".
  { iDestruct "H" as (v) "[% _]". apply val_stuck in Hstep; simplify_eq. }
  rewrite pvs_eq /pvs_def.
  iVs ("H" $! σ1 with "Hσ [Hw HE]") as "[H|(Hw & HE & _ & H)]"; first by iFrame.
  { iVsIntro; iNext. by iExFalso. }
  iVsIntro; iNext.
  by iVs ("H" $! e2 σ2 ef with "[%] [Hw HE]") as "[?|($ & $ & $ & $)]";
    [done|by iFrame|rewrite /uPred_now_True; eauto|].
Qed.

Lemma wptp_step e1 t1 t2 σ1 σ2 Φ :
  step (e1 :: t1,σ1) (t2, σ2) →
  world σ1 ★ WP e1 {{ Φ }} ★ wptp t1
  =r=> ∃ e2 t2', t2 = e2 :: t2' ★ ▷ |=r=> ◇ (world σ2 ★ WP e2 {{ Φ }} ★ wptp t2').
Proof.
  iIntros (Hstep) "(HW & He & Ht)".
  destruct Hstep as [e1' σ1' e2' σ2' ef [|? t1'] t2' ?? Hstep]; simplify_eq/=.
  - iExists e2', (t2' ++ option_list ef); iSplitR; first eauto.
    rewrite wptp_app wptp_fork. iFrame "Ht". iApply wp_step; try iFrame; eauto.
  - iExists e, (t1' ++ e2' :: t2' ++ option_list ef); iSplitR; first eauto.
    rewrite !wptp_app !wptp_cons wptp_app wptp_fork.
    iDestruct "Ht" as "($ & He' & $)"; iFrame "He".
    iApply wp_step; try iFrame; eauto.
Qed.

Lemma wptp_steps n e1 t1 t2 σ1 σ2 Φ :
  nsteps step n (e1 :: t1, σ1) (t2, σ2) →
  world σ1 ★ WP e1 {{ Φ }} ★ wptp t1 ⊢
  Nat.iter (S n) (λ P, |=r=> ▷ P) (∃ e2 t2',
    t2 = e2 :: t2' ★ world σ2 ★ WP e2 {{ Φ }} ★ wptp t2').
Proof.
  revert e1 t1 t2 σ1 σ2; simpl; induction n as [|n IH]=> e1 t1 t2 σ1 σ2 /=.
  { inversion_clear 1; iIntros "?"; eauto 10. }
  iIntros (Hsteps) "H". inversion_clear Hsteps as [|?? [t1' σ1']].
  iVs (wptp_step with "H") as (e1' t1'') "[% H]"; first eauto; simplify_eq.
  iVsIntro; iNext; iVs "H" as "[?|?]"; first (iVsIntro; iNext; by iExFalso).
  by iApply IH.
Qed.

Instance rvs_iter_mono n : Proper ((⊢) ==> (⊢)) (Nat.iter n (λ P, |=r=> ▷ P)%I).
Proof. intros P Q HP. induction n; simpl; do 2?f_equiv; auto. Qed.

Lemma wptp_result n e1 t1 v2 t2 σ1 σ2 φ :
  nsteps step n (e1 :: t1, σ1) (of_val v2 :: t2, σ2) →
  world σ1 ★ WP e1 {{ v, ■ φ v }} ★ wptp t1 ⊢
  Nat.iter (S (S n)) (λ P, |=r=> ▷ P) (■ φ v2).
Proof.
  intros. rewrite wptp_steps // (Nat_iter_S_r (S n)); apply rvs_iter_mono.
  iDestruct 1 as (e2 t2') "(% & (Hw & HE & _) & H & _)"; simplify_eq.
  iDestruct (wp_value_inv with "H") as "H". rewrite pvs_eq /pvs_def.
  iVs ("H" with "[Hw HE]") as "[?|(_ & _ & $)]"; [by iFrame| |done].
  iVsIntro; iNext; by iExFalso.
Qed.

Lemma wp_safe e σ Φ :
  world σ ★ WP e {{ Φ }} =r=> ▷ ■ (is_Some (to_val e) ∨ reducible e σ).
Proof.
  rewrite wp_unfold /wp_pre. iIntros "[(Hw&HE&Hσ) [H|[_ H]]]".
  { iDestruct "H" as (v) "[% _]"; eauto 10. }
  rewrite pvs_eq. iVs ("H" with "* Hσ [-]") as "[H|(?&?&%&?)]"; first by iFrame.
  iVsIntro; iNext; by iExFalso. eauto 10.
Qed.

Lemma wptp_safe n e1 e2 t1 t2 σ1 σ2 Φ :
  nsteps step n (e1 :: t1, σ1) (t2, σ2) → e2 ∈ t2 →
  world σ1 ★ WP e1 {{ Φ }} ★ wptp t1 ⊢
  Nat.iter (S (S n)) (λ P, |=r=> ▷ P) (■ (is_Some (to_val e2) ∨ reducible e2 σ2)).
Proof.
  intros ? He2. rewrite wptp_steps // (Nat_iter_S_r (S n)); apply rvs_iter_mono.
  iDestruct 1 as (e2' t2') "(% & Hw & H & Htp)"; simplify_eq.
  apply elem_of_cons in He2 as [<-|?]; first (iApply wp_safe; by iFrame "Hw H").
  iApply wp_safe. iFrame "Hw".
  iApply (big_sep_elem_of with "Htp"); apply elem_of_list_fmap; eauto.
Qed.
End adequacy.

Theorem adequacy_result `{irisPreG Λ Σ} e v2 t2 σ1 σ2 φ :
  (∀ `{irisG Λ Σ}, ownP σ1 ⊢ WP e {{ v, ■ φ v }}) →
  rtc step ([e], σ1) (of_val v2 :: t2, σ2) →
  φ v2.
Proof.
  intros Hwp [n ?]%rtc_nsteps.
  eapply (adequacy (M:=iResUR Σ) _ (S (S (S n)))); iIntros "".
  rewrite Nat_iter_S. iVs (iris_alloc σ1) as (?) "(?&?&?&Hσ)".
  iVsIntro. iNext. iApply wptp_result; eauto.
  iFrame. iSplitL. by iApply Hwp. done.
Qed.

Lemma wp_adequacy_reducible `{irisPreG Λ Σ} e1 e2 t2 σ1 σ2 Φ :
  (∀ `{irisG Λ Σ}, ownP σ1 ⊢ WP e1 {{ Φ }}) →
  rtc step ([e1], σ1) (t2, σ2) →
  e2 ∈ t2 → (is_Some (to_val e2) ∨ reducible e2 σ2).
Proof.
  intros Hwp [n ?]%rtc_nsteps ?.
  eapply (adequacy (M:=iResUR Σ) _ (S (S (S n)))); iIntros "".
  rewrite Nat_iter_S. iVs (iris_alloc σ1) as (?) "(Hw & HE & Hσ & Hσf)".
  iVsIntro. iNext. iApply wptp_safe; eauto.
  iFrame "Hw HE Hσ". iSplitL. by iApply Hwp. done.
Qed.

Theorem wp_adequacy_safe `{irisPreG Λ Σ} e1 t2 σ1 σ2 Φ :
  (∀ `{irisG Λ Σ}, ownP σ1 ⊢ WP e1 {{ Φ }}) →
  rtc step ([e1], σ1) (t2, σ2) →
  Forall (λ e, is_Some (to_val e)) t2 ∨ ∃ t3 σ3, step (t2, σ2) (t3, σ3).
Proof.
  intros.
  destruct (decide (Forall (λ e, is_Some (to_val e)) t2)) as [|Ht2]; [by left|].
  apply (not_Forall_Exists _), Exists_exists in Ht2; destruct Ht2 as (e2&?&He2).
  destruct (wp_adequacy_reducible e1 e2 t2 σ1 σ2 Φ) as [?|(e3&σ3&ef&?)];
    rewrite ?eq_None_not_Some; auto.
  { exfalso. eauto. }
  destruct (elem_of_list_split t2 e2) as (t2'&t2''&->); auto.
  right; exists (t2' ++ e3 :: t2'' ++ option_list ef), σ3; econstructor; eauto.
Qed.
