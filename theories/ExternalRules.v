From mathcomp Require Import ssreflect.
Set Bullet Behavior "Strict Subproofs".

Generalizable All Variables.

Require Import Unicode.Utf8 Program.Equality Program.Basics omega.Omega.
From gctt Require Import Axioms Var Term ExternalSyn Interp Tower Closure Sequent InternalRules.
From gctt Require InternalRules.
Module IR := InternalRules.

Local Hint Extern 40 =>
match goal with
| |- context[(_.⦃_⦄)%ectx] => rewrite -interp_ctx_clk_naturality /compose; simplify_eqs
| |- context[(_.⦃_⦄)%etm] => rewrite -interp_tm_clk_naturality /compose; simplify_eqs
| |- context[(_.[_])%etm] => try rewrite -interp_tm_var_naturality /compose; try rewrite -interp_tm_var_ren_naturality /compose; simplify_eqs
| |- context[(_ ⫽ _)%etm] => Term.simplify_subst
end.

Local Hint Extern 20 => IR.Univ.tac.
Local Hint Resolve IR.General.ty_eq_refl_left IR.General.ty_eq_trans IR.General.ty_eq_symm IR.General.mem_eq_trans IR.General.mem_eq_symm IR.General.env_eq_refl_left IR.General.env_eq_symm.

Tactic Notation "explode" "functionality" uconstr(𝒟) :=
  let X := fresh in
  (have X := (IR.General.functionality_square 𝒟));
  (edestruct X as [? [? ?]]); simpl in *; eauto.

Module Conversion.
  Module Structural.
    Theorem symm {Λ Ψ e1 e2} :
      ⟦ Λ ∣ Ψ ⊢ e1 ≃ e2 ⟧
      → ⟦ Λ ∣ Ψ ⊢ e2 ≃ e1 ⟧.
    Proof.
      move=> D κs γ v.
      specialize (D κs γ v).
      intuition.
    Qed.

    Theorem trans {Λ Ψ e1 e2 e3} :
      ⟦ Λ ∣ Ψ ⊢ e1 ≃ e2 ⟧
      → ⟦ Λ ∣ Ψ ⊢ e2 ≃ e3 ⟧
      → ⟦ Λ ∣ Ψ ⊢ e1 ≃ e3 ⟧.
    Proof.
      move=> 𝒟 ℰ κs γ v.
      specialize (𝒟 κs γ v).
      specialize (ℰ κs γ v).
      intuition.
    Qed.
  End Structural.

  Theorem fst_of_pair {Λ Ψ e1 e2} :
    ⟦ Λ ∣ Ψ ⊢ ⟨e1, e2⟩ .1 ≃ e1 ⟧.
  Proof.
    move=> κs γ v.
    split; move=> [𝒟1 𝒟2].
    - split; auto.
      dependent destruction 𝒟1.
      + OpSem.destruct_evals.
      + dependent destruction H.
        * OpSem.destruct_evals.
        * eauto.
    - split; auto; simpl.
      econstructor.
      + apply: OpSem.step_fst_pair.
      + auto.
  Qed.
End Conversion.

Module General.
  Theorem hypothesis `{Γ : ECtx.t Λ Ψ} {A} :
    ⟦ Λ ∣ Γ ∙ A ≫ A.[^1] ∋ @0 ≐ @0 ⟧.
  Proof.
    move=> κs Γctx ty γ0 γ1 γ01.
    case: γ01 => [_ γ01].
    auto.
  Qed.

  (* TODO: fix notation ? *)
  Theorem weakening `{Γ : ECtx.t Λ Ψ} i {A B e0 e1} :
    ⟦ Λ ∣ Γ ≫ A ∋ e0 ≐ e1 ⟧
    → ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ A ≐ A ⟧
    → ⟦ Λ ∣ Γ ∙ B ≫ (A.[^1]) ∋ (e0.[^1]) ≐ (e1.[^1]) ⟧.
  Proof.
    move=> 𝒟 ℰ κs ℱ 𝒢 γ0 γ1 γ01.
    repeat rewrite -interp_tm_var_ren_naturality.
    Term.simplify_subst.
    apply: 𝒟.
    - by case: ℱ.
    - IR.Univ.tac.
      apply: ℰ; eauto.
      by case: ℱ.
    - by case: γ01.
  Qed.

  Theorem conv_mem `{Γ : ECtx.t Λ Ψ} {A e00} e01 {e1} :
    ⟦ Λ ∣ Ψ ⊢ e00 ≃ e01 ⟧
    → ⟦ Λ ∣ Γ ≫ A ∋ e01 ≐ e1 ⟧
    → ⟦ Λ ∣ Γ ≫ A ∋ e00 ≐ e1 ⟧.
  Proof.
    move=> 𝒟 ℰ ? ? ? ? ? ?.
    apply: IR.General.mem_eq_conv.
    - eauto.
    - move=> ?; edestruct 𝒟; eassumption.
    - apply: ℰ; eauto.
  Qed.

  Theorem conv_ty `{Γ : ECtx.t Λ Ψ} A1 {A0 e0 e1} :
    ⟦ Λ ∣ Ψ ⊢ A0 ≃ A1 ⟧
    → ⟦ Λ ∣ Γ ≫ A1 ∋ e0 ≐ e1 ⟧
    → ⟦ Λ ∣ Γ ≫ A0 ∋ e0 ≐ e1 ⟧.
  Proof.
    move=> 𝒟 ℰ κs ? ? ? ? ?.
    apply: IR.General.mem_eq_conv_ty.
    - eauto.
    - move=> ?; edestruct 𝒟; eauto.
    - apply: ℰ; eauto.
      move=> ? ? ?.
      apply: IR.General.ty_eq_conv.
      + eauto.
      + move=> ?; edestruct 𝒟; eassumption.
      + apply: IR.General.ty_eq_symm.
        apply: IR.General.ty_eq_conv.
        * eauto.
        * move=> ?; edestruct 𝒟; eassumption.
        * eauto.
  Qed.

  Theorem eq_symm `{Γ : ECtx.t Λ Ψ} {A e0 e1} :
    ⟦ Λ ∣ Γ ≫ A ∋ e0 ≐ e1 ⟧
    → ⟦ Λ ∣ Γ ≫ A ∋ e1 ≐ e0 ⟧.
  Proof.
    move=> 𝒟 κs Γctx ℰ γ0 γ1 γ01.
    apply: IR.General.mem_eq_symm; first by eauto.
    apply: IR.General.replace_ty_in_mem_eq; eauto.
    apply: 𝒟; eauto.
  Qed.

  Theorem eq_trans `{Γ : ECtx.t Λ Ψ} {A e0 e1 e2} :
    ⟦ Λ ∣ Γ ≫ A ∋ e1 ≐ e2 ⟧
    → ⟦ Λ ∣ Γ ≫ A ∋ e0 ≐ e1 ⟧
    → ⟦ Λ ∣ Γ ≫ A ∋ e0 ≐ e2 ⟧.
  Proof.
    move=> 𝒟 ℰ ? ? ? ? ? ?.
    apply: IR.General.mem_eq_trans; eauto.
    - apply: 𝒟; eauto.
    - apply: ℰ; eauto.
  Qed.

  Theorem eq_refl_left `{Γ : ECtx.t Λ Ψ} {A e0 e1} :
    ⟦ Λ ∣ Γ ≫ A ∋ e0 ≐ e1 ⟧
    → ⟦ Λ ∣ Γ ≫ A ∋ e0 ≐ e0 ⟧.
  Proof.
    move=> 𝒟.
    apply: eq_trans.
    - apply: eq_symm.
      eassumption.
    - eassumption.
  Qed.

  Theorem replace_ty `{Γ : ECtx.t Λ Ψ} i {A0 A1 e1 e2} :
    ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ A0 ≐ A1 ⟧
    → ⟦ Λ ∣ Γ ≫ A0 ∋ e1 ≐ e2 ⟧
    → ⟦ Λ ∣ Γ ≫ A1 ∋ e1 ≐ e2 ⟧.
  Proof.
    move=> 𝒟 ℰ κs ℱ _ ? ? ?.
    apply: IR.General.replace_ty_in_mem_eq.
    - apply: ℰ; eauto.
      move=> γ0' γ1' γ01'.
      IR.Univ.tac.
      explode functionality (𝒟 _ _ _).
    - IR.Univ.tac.
      apply: 𝒟; auto.
      apply: IR.General.env_eq_refl_left; eassumption.
  Qed.

  Theorem mem_conv_all `{Γ : ECtx.t Λ Ψ} A' e0' e1' {A e0 e1} :
    ⟦ Λ ∣ Ψ ⊢ A ≃ A' ⟧
    → ⟦ Λ ∣ Ψ ⊢ e0 ≃ e0' ⟧
    → ⟦ Λ ∣ Ψ ⊢ e1 ≃ e1' ⟧
    → ⟦ Λ ∣ Γ ≫ A' ∋ e0' ≐ e1' ⟧
    → ⟦ Λ ∣ Γ ≫ A ∋ e0 ≐ e1 ⟧.
  Proof.
    move=> *.
    apply: conv_ty; eauto.
    apply: conv_mem; eauto.
    apply: eq_symm.
    apply: conv_mem; eauto.
    by apply: eq_symm.
  Qed.

  Theorem univ_formation i j `{Γ : ECtx.t Λ Ψ} :
    i < j
    → ⟦ Λ ∣ Γ ≫ 𝕌[j] ∋ 𝕌[i] ≐ 𝕌[i] ⟧.
  Proof.
    move=> ? ? ? ? ? ? ? //=.
    apply: IR.Univ.intro.
    apply: IR.Univ.formation_lvl.
    assumption.
  Qed.
End General.

Module Unit.
  Theorem ax_equality `{Γ : ECtx.t Λ Ψ} :
    ⟦ Λ ∣ Γ ≫ 𝟙 ∋ ★ ≐ ★ ⟧.
  Proof.
    move=> ? ? ? ? ? ?.
    apply: IR.Unit.ax_equality.
  Qed.
End Unit.


Module Bool.
  Theorem univ_eq `{Γ : ECtx.t Λ Ψ} i :
    ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ 𝟚 ≐ 𝟚 ⟧.
  Proof.
    move=> ? ? ? ? ? ?.
    IR.Bool.tac.
  Qed.

  Theorem tt_equality `{Γ : ECtx.t Λ Ψ} :
    ⟦ Λ ∣ Γ ≫ 𝟚 ∋ ETm.tt ≐ ETm.tt ⟧.
  Proof.
    move=> ? ? ? ? ? ?.
    IR.Bool.tac.
  Qed.

  Theorem ff_equality `{Γ : ECtx.t Λ Ψ} :
    ⟦ Λ ∣ Γ ≫ 𝟚 ∋ ETm.ff ≐ ETm.ff ⟧.
  Proof.
    move=> ? ? ? ? ? ?.
    IR.Bool.tac.
  Qed.
End Bool.


Module Prod.
  Theorem univ_eq `{Γ : ECtx.t Λ Ψ} i {A0 A1 B0 B1} :
    ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ A0 ≐ A1 ⟧
    → ⟦ Λ ∣ Γ ∙ A0 ≫ 𝕌[i] ∋ B0 ≐ B1 ⟧
    → ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ (A0 × B0) ≐ (A1 × B1) ⟧.
  Proof.
    move=> 𝒟 ℰ κs Γctx ℱ γ0 γ1 γ01 //=.
    apply: IR.Prod.univ_eq.
    - by apply: 𝒟.
    - move=> ? ? γ01' //=.
      Term.simplify_subst.
      T.efwd_thru ℰ; eauto.
      + split; Term.simplify_subst.
        * T.use γ01; f_equal; T.eqcd; Term.simplify_subst.
        * case: γ01' => _ 𝒢.
          T.use 𝒢; Term.simplify_subst.
      + split; eauto.
        move=> ? ? ?.
        explode functionality (𝒟 _ _ _).
  Qed.

  (* ugly proof ! *)
  Theorem intro `{Γ : ECtx.t Λ Ψ} {i A B e00 e01 e10 e11} :
    ⟦ Λ ∣ Γ ≫ A ∋ e00 ≐ e10 ⟧
    → ⟦ Λ ∣ Γ ≫ B ⫽ Sub.inst0 e00 ∋ e01 ≐ e11 ⟧
    → ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ A ≐ A ⟧
    → ⟦ Λ ∣ Γ ∙ A ≫ 𝕌[i] ∋ B ≐ B ⟧
    → ⟦ Λ ∣ Γ ≫ A × B ∋ ⟨e00, e01⟩ ≐ ⟨e10, e11⟩ ⟧.
  Proof.
    move=> 𝒟 ℰ ℱ 𝒢 κs Γctx ℋ γ0 γ1 γ01 //=.
    apply: IR.Prod.intro.
    - apply: 𝒟; eauto.
      IR.Univ.tac.
      apply: ℱ; eauto.
    - Term.simplify_subst.
      T.efwd_thru ℰ.
      + rewrite -interp_tm_subst_naturality.
        f_equal; eauto.
        Term.simplify_subst.
        dependent induction x; Term.simplify_subst.
      + move=> γ0' γ1' γ01'.
        IR.Univ.tac.
        repeat rewrite -interp_tm_subst_naturality.
        apply: 𝒢; eauto.
        * split; eauto.
          IR.Univ.tac.
          apply: ℱ; auto.
        * split; eauto.
          Term.simplify_subst.
          apply: (@IR.General.replace_ty_in_mem_eq ((⟦ A ⟧ κs) ⫽ γ1')%tm).
          ** explode functionality (𝒟 _ _ _).
             *** IR.Univ.tac.
                 apply: ℱ; auto.
             *** apply: IR.General.mem_eq_trans; auto.
                 **** eauto.
                 **** apply: (@IR.General.replace_ty_in_mem_eq ((⟦ A ⟧ κs) ⫽ γ0')%tm).
                      ***** eauto.
                      ***** explode functionality (ℱ _ _ _).
          ** explode functionality (ℱ _ _ _).
    - IR.Univ.tac.
      apply: ℱ; eauto.
    - move=> γ0' γ1' γ01'.
      Term.simplify_subst.
      IR.Univ.tac.
      apply: 𝒢; auto.
      + split; eauto.
        move=> ? ? ?.
        IR.Univ.tac.
        apply: ℱ; auto.
      + split; Term.simplify_subst.
        * suff 𝒥 : τω ⊧ ⟦ Γ ⟧ κs ∋⋆ γ0 ∼ γ0; eauto.
          T.use 𝒥; Term.simplify_subst.
        * case: γ01' => _; simplify_eqs => 𝒥.
          apply: IR.Level.eq_mem_from_level.
          T.use 𝒥.
          Term.simplify_subst.
  Qed.
End Prod.


Module Isect.

  Theorem univ_eq `{Γ : ECtx.t Λ Ψ} i {A0 A1} :
    ⟦ S Λ ∣ Γ.⦃^1⦄ ≫ 𝕌[i] ∋ A0 ≐ A1 ⟧
    → ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ ⋂ A0 ≐ ⋂ A1 ⟧.
  Proof.
    move=> 𝒟 κs Γctx ℰ γ0 γ1 γ01 //=.
    apply: IR.Univ.intro.
    apply: IR.Isect.formation => κ.
    T.efwd 𝒟; eauto.
  Qed.

  Theorem intro `{Γ : ECtx.t Λ Ψ} i {A e0 e1} :
    ⟦ S Λ ∣ Γ.⦃^1⦄ ≫ A ∋ (e0.⦃^1⦄) ≐ (e1.⦃^1⦄) ⟧
    → ⟦ S Λ ∣ Γ.⦃^1⦄ ≫ 𝕌[i] ∋ A ≐ A ⟧
    → ⟦ Λ ∣ Γ ≫ ⋂ A ∋ e0 ≐ e1 ⟧.
  Proof.
    move=> 𝒟 ℱ κs ? ℰ ? ? ? //=.
    apply: IR.Isect.intro.
    - IR.Univ.tac.
      apply: univ_eq; eauto.
    - move=> κ; T.efwd_thru 𝒟.
      IR.Univ.tac.
      apply: ℱ; eauto.
  Qed.

  Theorem irrelevance `{Γ : ECtx.t Λ Ψ} {i A} :
    ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ A ≐ A ⟧
    → ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ A ≐ ⋂ (A.⦃^1⦄) ⟧.
  Proof.
    move=> 𝒟 κs ? ? γ0 γ1 γ01; simplify_eqs.
    replace (λ κ:𝕂, (⟦_.⦃_⦄ ⟧ _) ⫽ _)%tm with (λ κ:𝕂, (⟦A⟧ κs) ⫽ γ1)%tm.
    - apply: IR.Univ.intro.
      apply: IR.Isect.irrelevance.
      apply: IR.Univ.inversion.
      apply: 𝒟; eauto.
    - Term.simplify_subst; eauto.
  Qed.

  Theorem cartesian `{Γ : ECtx.t Λ Ψ} i {A0 B0 A1 B1} :
    ⟦ S Λ ∣ Γ.⦃^1⦄ ≫ 𝕌[i] ∋ A0 ≐ A1 ⟧
    → ⟦ S Λ ∣ Γ.⦃^1⦄ ≫ 𝕌[i] ∋ B0 ≐ B1 ⟧
    → ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ (⋂ (A0 × B0.[^1])) ≐ ((⋂ A1) × (⋂ B1.[^1])) ⟧.
  Proof.
    move=> 𝒟 ℰ κs ℱ 𝒢 γ0 γ1 γ01 //=.
    apply: IR.Univ.intro.
    Term.simplify_subst.
    have R :=
      @IR.Isect.cartesian
        i
        (fun κ => (⟦ A0 ⟧ κ ∷ κs) ⫽ γ0)%tm
        (fun κ => (⟦ B0 ⟧ κ ∷ κs) ⫽ γ0)%tm
        (fun κ => (⟦ A1 ⟧ κ ∷ κs) ⫽ γ1)%tm
        (fun κ => (⟦ B1 ⟧ κ ∷ κs) ⫽ γ1)%tm.
    T.efwd_thru R.
    - T.eqcd => κ; f_equal; Term.simplify_subst.
      rewrite -interp_tm_var_ren_naturality.
      Term.simplify_subst.
    - Term.simplify_subst.
      rewrite -interp_tm_ren_naturality;
      Term.simplify_subst.
      by dependent induction x0.
    - move=> κ.
      IR.Univ.tac.
      apply: ℰ; auto.
    - move=> κ.
      IR.Univ.tac.
      apply: 𝒟; auto.
  Qed.
End Isect.

Module Later.
  Theorem univ_eq `{Γ : ECtx.t Λ Ψ} i {k A0 A1} :
    ⟦ Λ ∣ Γ ≫ ▶[k] 𝕌[i] ∋ A0 ≐ A1 ⟧
    → ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ ▶[k] A0 ≐ ▶[k] A1 ⟧.
  Proof.
    move=> 𝒟 ? ? ? ? ? ? //=.
    apply: IR.Later.univ_eq.
    apply: 𝒟; eauto.

    move=> ? ? ? //=.
    apply: Later.formationω.
    apply: Later.next.
    eauto.
  Qed.

  Theorem intro `{Γ : ECtx.t Λ Ψ} {k i A e0 e1} :
    ⟦ Λ ∣ Γ ≫ A ∋ e0 ≐ e1 ⟧
    → ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ A ≐ A ⟧
    → ⟦ Λ ∣ Γ ≫ ▶[k] A ∋ e0 ≐ e1 ⟧.
  Proof.
    move=> 𝒟 ℰ ? ? ? ? ? ? //=.
    apply: IR.Later.intro.
    apply: Later.next.
    apply: 𝒟; auto.

    IR.Univ.tac.
    apply: ℰ; eauto.
  Qed.

  Theorem force `{Γ : ECtx.t Λ Ψ} {i A B} :
    ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ ⋂ A ≐ ⋂ B ⟧
    → ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ ⋂ ▶[#0] A ≐ ⋂ B ⟧.
  Proof.
    move=> 𝒟 ? ? ? ? ? ? //=.
    apply: IR.Univ.intro.
    apply: IR.Later.force.
    IR.Univ.tac.
    apply: 𝒟; eauto.
  Qed.

  Theorem induction `{Γ : ECtx.t Λ Ψ} k {A e0 e1} :
    ⟦ Λ ∣ Γ ∙ ▶[k] A ≫ A.[^1] ∋ e0 ≐ e1 ⟧
    → ⟦ Λ ∣ Γ ≫ A ∋ μ{ e0 } ≐ μ{ e1 } ⟧.
  Proof.
    move=> 𝒟 κs ? ℰ //=.
    apply: (IR.Later.loeb_induction_open (κs k)).
    move=> ? ? ?.
    T.efwd_thru 𝒟.
    - move=> ? ? [? ?].
      T.efwd_thru ℰ.
    - split; auto.
      move=> ? ? ?.
      apply: IR.Later.formationω.
      apply: Later.next.
      auto.
  Qed.
End Later.


Module Examples.

  (* Guarded stream of bits. *)
  Example BitStream {Λ Ψ} (k : Var Λ) : ETm.t Λ Ψ :=
    μ{ 𝟚 × ▶[k] @1 }%etm.

  Arguments BitStream [Λ Ψ] k%eclk.

  (* Coinductive sequence of bits. *)
  Example BitSeq {Λ Ψ} : ETm.t Λ Ψ :=
    (⋂ (BitStream #0))%etm.

  Example BitStream_wf `{Γ : ECtx.t Λ Ψ} i {k} :
    ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ (BitStream k) ≐ (BitStream k) ⟧.
  Proof.
    apply: (Later.induction k).
    apply: Prod.univ_eq.
    - apply: Bool.univ_eq.
    - apply: Later.univ_eq.
      move=> κs 𝒟 ℰ γ0 γ1 γ01.
      (* annoying !*)
      have R := @General.weakening Λ (S Ψ) (Γ∙_)%ectx (S i) (▶[k] 𝕌[i])%etm 𝟚%etm @0%etm @0%etm _ _ _ _ _ γ0 γ1 γ01.
      T.efwd_thru R; eauto.
      + apply: Later.univ_eq.
        apply: Later.intro.
        * apply: General.univ_formation; auto.
        * apply: General.univ_formation; auto.
      + apply: General.hypothesis.
  Qed.

  Example BitSeq_wf `{Γ : ECtx.t Λ Ψ} {i} :
    ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ BitSeq ≐ BitSeq ⟧.
  Proof.
    apply: Isect.univ_eq.
    apply: BitStream_wf.
  Qed.

  Example Ones {Λ Ψ} : ETm.t Λ Ψ :=
    μ{ ⟨ETm.tt, @0⟩ }%etm.


  Example BitStream_unfold `{Γ : ECtx.t Λ Ψ} {i k} :
    ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ BitStream k ≐ (𝟚 × ▶[k] BitStream k) ⟧.
  Proof.
    apply: (General.conv_mem (𝟚 × ▶[k] BitStream k)%etm).
    - move=> ? ?; apply: OpSem.fix_unfold.
    - apply: Prod.univ_eq.
      + apply: Bool.univ_eq.
      + apply: Later.univ_eq.
        apply: Later.intro.
        * apply: BitStream_wf.
        * apply: (General.univ_formation i).
          auto.
  Qed.

  Example Ones_wf_guarded `{Γ : ECtx.t Λ Ψ} {k} :
    ⟦ Λ ∣ Γ ≫ BitStream k ∋ Ones ≐ Ones ⟧.
  Proof.
    apply: (Later.induction k).
    apply: (General.replace_ty 0).
    - apply: General.eq_symm.
      apply: BitStream_unfold.
    - apply: Prod.intro.
      + by apply: Bool.tt_equality.
      + by apply: General.hypothesis.
      + by apply: (Bool.univ_eq 0).
      + apply: (Later.univ_eq 0).
        apply: Later.intro.
        * by apply: BitStream_wf.
        * by apply: General.univ_formation.
  Qed.

  Example Ones_wf_infinite `{Γ : ECtx.t Λ Ψ} :
    ⟦ Λ ∣ Γ ≫ BitSeq ∋ Ones ≐ Ones ⟧.
  Proof.
    apply: Isect.intro.
    apply: Ones_wf_guarded.
    apply: (BitStream_wf 0).
  Qed.


  Example BitSeq_unfold `{Γ : ECtx.t Λ Ψ} i :
    ⟦ Λ ∣ Γ ≫ 𝕌[i] ∋ BitSeq ≐ (𝟚 × BitSeq) ⟧.
  Proof.
    apply: General.eq_trans.
    - apply: General.eq_trans.
      + apply: Prod.univ_eq.
        * apply: General.eq_symm.
          apply: Isect.irrelevance.
          apply: Bool.univ_eq.
        * apply: Later.force.
          apply: BitSeq_wf.
      + replace _ with (((⋂ ▶[#0] BitStream #0).[^1])%etm : ETm.t Λ (S Ψ)); auto.
        apply: Isect.cartesian.
        * apply: Bool.univ_eq.
        * apply: Later.univ_eq.
          apply: Later.intro.
          ** by apply: BitStream_wf.
          ** by apply: General.univ_formation.
    - apply: Isect.univ_eq.
      apply: BitStream_unfold.
  Qed.
End Examples.