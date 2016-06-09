Require Import Arith.
Require Import Omega.
Require Import List.
Require Import Prog ProgMonad.
Require Import Pred PredCrash.
Require Import Hoare.
Require Import Word.
Require Import AsyncDisk.
Require Import Hashmap.

Set Implicit Arguments.


Hint Extern 1 (exists _, hashmap_subset _ _ _) => try solve_hashmap_subset.

(* Helpers for existential variables *)

Ltac set_evars :=
  repeat match goal with
              | [ |- context[?e] ] => is_evar e; 
                 match type of e with
                 | prod _ _ => idtac
                 | _ => let H := fresh in set (H := e)
                 end
            end.

Ltac subst_evars :=
  repeat match goal with
              | [ H := ?e |- _ ] => is_evar e; subst H
            end.

Ltac set_evars_in H :=
  repeat match type of H with
              | context[?e] => is_evar e; let E := fresh in set (E := e) in H
            end.

Ltac equate x y :=
  let dummy := constr:(eq_refl x : x = y) in idtac.

Ltac eassign' t :=
  match goal with
  | [ |- context [?x] ] => is_evar x; equate x t
  end.

Tactic Notation "eassign" constr(t) := eassign' t.


(** * Helpers for keeping track of variable names *)

Definition varname_type (_ : unit) := unit.
Definition varname_val (_ : unit) := tt.
Notation "'VARNAME' ( varname )" := (forall (varname : unit), varname_type varname).

Ltac clear_varname :=
  match goal with
  | [ H: VARNAME(vn) |- _ ] => clear H
  end.

Ltac destruct_prod :=
  match goal with
  | [ v: valuset |- _ ] =>
    let v0 := fresh v "_cur" in
    let v1 := fresh v "_old" in
    destruct v as [v0 v1]
  | [ H: (VARNAME(vn) * ?b)%type |- _ ] => destruct H as [? ?vn]
  | [ H: (?a * ?b)%type |- _ ] => destruct H
  end.

Lemma eexists_pair: forall A B p,
  (exists (a:A) (b:B), p (a, b))
  -> (exists (e:A*B), p e).
Proof.
  intros.
  destruct H as [a H].
  destruct H as [b H].
  exists (a, b); auto.
Qed.

Theorem destruct_varname1_0 : forall AN A (p : AN * A),
  exists an a, p = (an, a).
Proof.
  intros; destruct p; eauto.
Qed.

Theorem destruct_varname1_1 : forall AN A B (p : AN * A * B ),
  exists an a b, p = (an, a, b).
Proof.
  intros; do 2 destruct p; eauto.
Qed.

Theorem destruct_varname1_2 : forall AN A B C (p : AN * A * B * C),
  exists an a b c, p = (an, a, b, c).
Proof.
  intros; repeat destruct_prod; repeat eexists.
Qed.

Theorem destruct_varname1_4 : forall AN A B C D E (p : AN * A * B * C * D * E),
  exists an a b c d e, p = (an, a, b, c, d, e).
Proof.
  intros; repeat destruct_prod; repeat eexists.
Qed.

Theorem destruct_varname1_8 : forall AN A B C D E F G (p : AN * A * B * C * D * E * F * G),
  exists an a b c d e f g, p = (an, a, b, c, d, e, f, g).
Proof.
  intros; repeat destruct_prod; repeat eexists.
Qed.

Theorem destruct_varname2 : forall AN BN A B C (p : (AN * A) * ((BN * B) * C) ),
  exists an a bn b c, p = ((an, a), ((bn, b), c)).
Proof.
  intros. repeat destruct_prod.
  repeat eexists.
Qed.

Theorem destruct_varname3 : forall AN BN CN A B C D (p : (AN * A) * ((BN * B) * ((CN * C) * D))),
  exists an a bn b cn c d, p = ((an, a), ((bn, b), ((cn, c), d))).
Proof.
  intros. repeat destruct_prod.
  repeat eexists.
Qed.

Theorem destruct_varname4 : forall AN BN CN DN A B C D E 
                  (p : (AN * A) * ((BN * B) * ((CN * C) * ((DN * D) * E)))),
  exists an a bn b cn c dn d e, p = ((an, a), ((bn, b), ((cn, c), ((dn, d), e)))).
Proof.
  intros. repeat destruct_prod.
  repeat eexists.
Qed.

Ltac destruct_varname1 :=
  match goal with
  | [ H : VARNAME (_) * _ |- _ ] => let Hx := fresh in
      pose proof (destruct_varname1_0 H) as Hx;
      match type of Hx with
      | exists (_ : VARNAME (vn)) _, _ = _ =>
        destruct Hx as [? [?vn Hx] ]
      end
  | [ H : VARNAME (_) * _ * _ |- _ ] => let Hx := fresh in
      pose proof (destruct_varname1_1 H) as Hx;
      match type of Hx with
      | exists (_ : VARNAME (vn)) _ _, _ = _ =>
        destruct Hx as [? [?vn [? Hx] ] ]
      end
  | [ H : VARNAME (_) * _ * _ * _ |- _ ] => let Hx := fresh in
      pose proof (destruct_varname1_2 H) as Hx;
      match type of Hx with
      | exists (_ : VARNAME (vn)) _ _ _, _ = _ =>
        destruct Hx as [? [?vn [? [? Hx] ] ] ]
      end
  | [ H : VARNAME (_) * _ * _ * _ * _ * _ |- _ ] => let Hx := fresh in
      pose proof (destruct_varname1_4 H) as Hx;
      match type of Hx with
      | exists (_ : VARNAME (vn)) _ _ _ _ _, _ = _ =>
        destruct Hx as [? [?vn [? [? [? [? Hx] ] ] ] ] ]
      end
  | [ H : VARNAME (_) * _ * _ * _ * _ * _ * _ * _ |- _ ] => let Hx := fresh in
      pose proof (destruct_varname1_8 H) as Hx;
      match type of Hx with
      | exists (_ : VARNAME (vn)) _ _ _ _ _ _ _, _ = _ =>
        destruct Hx as [? [?vn [? [? [? [? [? [? Hx] ] ] ] ] ] ] ]
      end
  end.

Ltac destruct_varname2 :=
  match goal with
  | [ H : VARNAME (_) * _ * ((VARNAME (_) * _) * _) |- _ ] => let Hx := fresh in
      pose proof (destruct_varname2 H) as Hx;
      match type of Hx with
      | exists (_ : VARNAME (vn1)) _ (_ : VARNAME (vn2)) _ _, _ = _ =>
        destruct Hx as [? [?vn1 [? [?vn2 [? Hx] ] ] ] ]
      end
  end.

Ltac destruct_varname3 :=
  match goal with
  | [ H : VARNAME (_) * _ * ((VARNAME (_) * _) * ((VARNAME (_) * _) * _)) |- _ ] => let Hx := fresh in
      pose proof (destruct_varname3 H) as Hx;
      match type of Hx with
      | exists (_ : VARNAME (vn1)) _ (_ : VARNAME (vn2)) _ (_ : VARNAME (vn3)) _ _, _ = _ =>
        destruct Hx as [? [?vn1 [? [?vn2 [? [?vn3 [? Hx] ] ] ] ] ] ]
      end
  end.

Ltac destruct_varname4 :=
  match goal with
  | [ H : VARNAME (_) * _ * ((VARNAME (_) * _) * ((VARNAME (_) * _) * ((VARNAME (_) * _) * _))) |- _ ] =>
      let Hx := fresh in
      pose proof (destruct_varname4 H) as Hx;
      match type of Hx with
      | exists (_ : VARNAME (vn1)) _ (_ : VARNAME (vn2)) _ (_ : VARNAME (vn3)) _ (_ : VARNAME (vn4)) _ _ , _ = _ =>
        destruct Hx as [? [?vn1 [? [?vn2 [? [?vn3 [? [?vn4 [? Hx] ] ] ] ] ] ] ] ]
      end
  end.

Ltac destruct_varnames :=
  repeat (( destruct_varname4 || destruct_varname3 || destruct_varname2 || destruct_varname1); subst).

Theorem destruct_pair2 : forall A B (p : A * B),
  exists a b, p = (a, b).
Proof.
  intros; destruct p; repeat eexists.
Qed.

Theorem destruct_pair4 : forall A B C D (p : A * B * C * D),
  exists a b c d, p = (a, b, c, d).
Proof.
  intros; do 3 destruct p; repeat eexists.
Qed.

Theorem destruct_pair6 : forall A B C D E F (p : A * B * C * D * E * F),
  exists a b c d e f, p = (a, b, c, d, e, f).
Proof.
  intros; do 5 destruct p; repeat eexists.
Qed.

Theorem destruct_pair8 : forall A B C D E F G H (p : A * B * C * D * E * F * G * H),
  exists a b c d e f g h, p = (a, b, c, d, e, f, g, h).
Proof.
  intros; do 7 destruct p; repeat eexists.
Qed.

Ltac destruct_pair2 :=
  match goal with
  | [ H : _ * _ |- _ ] => first [ clear H || let Hx := fresh in
      pose proof (destruct_pair2 H) as Hx;
      match type of Hx with
      | exists _ _, _ = _ =>
        let H1 := fresh H "_1" in let H2 := fresh H "_2" in
        destruct Hx as [H1 [H2 Hx] ]
      end ]
  end.

Ltac destruct_pair4 :=
  match goal with
  | [ H : _ * _ * _ * _ |- _ ] => first [ clear H || let Hx := fresh in
      pose proof (destruct_pair4 H) as Hx;
      match type of Hx with
      | exists _ _ _ _, _ = _ =>
        destruct Hx as [? [? [? [? Hx] ] ] ]
      end ]
  end.

Ltac destruct_pair6 :=
  match goal with
  | [ H : _ * _ * _ * _ * _ * _ |- _ ] => first [ clear H || let Hx := fresh in
      pose proof (destruct_pair6 H) as Hx;
      match type of Hx with
      | exists _ _ _ _ _ _, _ = _ =>
        destruct Hx as [? [? [? [? [? [? Hx] ] ] ] ] ]
      end ]
  end.


Ltac destruct_pair8 :=
  match goal with
  | [ H : _ * _ * _ * _ * _ * _ * _ * _ |- _ ] => first [ clear H ||  let Hx := fresh in
      pose proof (destruct_pair8 H) as Hx;
      match type of Hx with
      | exists _ _ _ _ _ _ _ _, _ = _ =>
        destruct Hx as [? [? [? [? [? [? [? [? Hx] ] ] ] ] ] ] ]
      end ]
  end.

Ltac destruct_pair_once :=
  match goal with
  | [ v: valuset |- _ ] =>
    let v0 := fresh v "_cur" in
    let v1 := fresh v "_old" in
    destruct v as [v0 v1]
  | _ => ( destruct_pair8 || destruct_pair6 || destruct_pair4 || destruct_pair2)
  end; subst.

Ltac destruct_pairs :=
  repeat (destruct_varnames; simpl in *; try destruct_pair_once).


(**
 * These "anon" names will currently show up for ghost variables inside for loops..
 *)
Lemma eexists_varname_pair : forall A B p,
  (exists (a:VARNAME(anon) * A) (b:VARNAME(anon) * B), p (varname_val, (snd a, snd b)))
  -> (exists (e:VARNAME(any) * (A*B)), p e).
Proof.
  intros.
  destruct H as [a H].
  destruct H as [b H].
  exists (varname_val, (snd a, snd b)); auto.
Qed.

Lemma eexists_varname_one : forall A p,
  (exists (a : A), p (varname_val, a))
  -> (exists (e : VARNAME(foo) * A), p e).
Proof.
  intros.
  destruct H as [a H].
  exists (varname_val, a); auto.
Qed.

Ltac eexists_one :=
  match goal with
  | [ |- exists (_ : unit), _ ] => exists tt
  | [ |- exists (_ : VARNAME(vn) * (?TA * ?TB)), _ ] =>
    apply eexists_varname_pair
  | [ |- exists (_ : VARNAME(vn) * ?T), _ ] =>
    let ev := fresh vn in
    evar (ev : T);
    apply eexists_varname_one;
    exists ev;
    unfold ev in *; clear ev
  | [ |- exists (_ : VARNAME(vn) * _ * _), _ ] =>
    apply eexists_pair
  | [ |- exists (_ : (_*_)), _ ] => apply eexists_pair
  | [ |- exists _, _ ] => eexists
  end.

(** * Separation logic proof automation *)

Ltac pred_apply' H := eapply pimpl_apply; [ | exact H ].

Ltac pred_apply := match goal with
  | [ H: _ ?m |- _ ?m ] => pred_apply' H
  | [ |- exists _, _ ] => eexists; pred_apply
  end.

Ltac pimpl_crash :=
  try match goal with
  | [ |- _ =p=> emp * _ ] => eapply pimpl_trans; [| eapply pimpl_star_emp ]
  end;
  set_evars;
  try match goal with
  | [ H: _ =p=> _ |- _ =p=> ?crash ] => eapply pimpl_trans; [| solve [ eapply H ] ]
  | [ H: forall _, _ =p=> _ |- _ =p=> ?crash ] => eapply pimpl_trans; [| solve [ eapply H ] ]
  end;
  subst_evars.

Definition pred_fold_left AT AEQ V (l : list (@pred AT AEQ V)) : pred :=
  match l with
  | nil => emp
  | a :: t => fold_left sep_star t a
  end.

Definition stars {AT AEQ V} (ps : list (@pred AT AEQ V)) :=
  pred_fold_left ps.
Arguments stars : simpl never.

Ltac sep_imply'' H := eapply pimpl_apply; [ | apply H ].

Ltac sep_imply' m :=
  match goal with
  | [ H : _ m |- _ ] => sep_imply'' H
  | [ H : _ _ m |- _ ] => sep_imply'' H
  | [ H : _ _ _ m |- _ ] => sep_imply'' H
  end.

Ltac sep_imply :=
  match goal with
  | [ |- _ ?m ] => sep_imply' m
  | [ |- _ _ ?m ] => sep_imply' m
  | [ |- _ _ _ ?m ] => sep_imply' m
  end.

Theorem start_normalizing_left : forall AT AEQ V PT (p : @pred AT AEQ V) q ps P,
  p <=p=> (exists (x:PT), stars (ps x) * [[P x]])%pred
  -> ((exists (x:PT), stars (ps x) * stars nil * [[P x]]) =p=> q)
  -> p =p=> q.
Proof.
  unfold stars; simpl; intros.
  rewrite <- H0.
  rewrite H.
  eapply pimpl_exists_l; intro eP.
  eapply pimpl_exists_r; exists eP.
  eapply pimpl_trans; [apply pimpl_star_emp|].
  eapply pimpl_trans; [apply sep_star_assoc|].
  apply piff_star_r. apply sep_star_comm.
Qed.

Theorem start_normalizing_right : forall AT AEQ V QT (p : @pred AT AEQ V) q qs Q,
  q <=p=> (exists (x:QT), stars (qs x) * [[Q x]])%pred
  -> (p =p=> (exists (x:QT), stars (qs x) * [[Q x]]))
  -> p =p=> q.
Proof.
  unfold stars; simpl; intros.
  rewrite H0.
  rewrite <- H.
  apply pimpl_refl.
Qed.

Theorem start_normalizing_apply : forall AT AEQ V PT (p : @pred AT AEQ V) ps P m,
  p <=p=> (exists (x:PT), stars (ps x) * [[P x]])%pred
  -> p m
  -> (exists (x:PT), stars (ps x) * [[P x]])%pred m.
Proof.
  firstorder.
Qed.

Theorem restart_canceling:
  forall AT AEQ V p (q : @pred AT AEQ V),
  (stars p * stars nil =p=> q) ->
  (stars nil * stars p =p=> q).
Proof.
  intros; eapply pimpl_trans; [ eapply sep_star_comm | eauto ].
Qed.

Lemma stars_prepend':
  forall AT AEQ V l x,
  fold_left sep_star l x <=p=> x * fold_left sep_star l (@emp AT AEQ V).
Proof.
  induction l.
  - simpl. intros.
    eapply piff_trans.
    apply emp_star.
    apply sep_star_comm.
  - simpl. intros.
    eapply piff_trans.
    eapply IHl.
    eapply piff_trans.
    eapply sep_star_assoc.
    eapply piff_star_l.
    eapply piff_comm.
    eapply piff_trans.
    eapply IHl.
    eapply piff_comm.
    eapply piff_trans.
    eapply emp_star.
    eapply piff_comm.
    eapply piff_trans.
    eapply sep_star_assoc.
    eapply piff_refl.
Qed.

Lemma stars_prepend:
  forall AT AEQ V l (x : @pred AT AEQ V),
  stars (x :: l) <=p=> x * stars l.
Proof.
  unfold stars, pred_fold_left; simpl; intros.
  destruct l.
  - simpl; split.
    eapply pimpl_trans; [| eapply sep_star_comm ]. eapply pimpl_star_emp.
    eapply pimpl_trans; [eapply sep_star_comm |]. eapply star_emp_pimpl.
  - eapply piff_trans. apply stars_prepend'.
    eapply piff_star_l.
    simpl.
    eapply piff_trans; [ apply stars_prepend' |].
    eapply piff_trans; [| apply piff_comm; apply stars_prepend' ].
    apply piff_star_r.
    split.
    apply star_emp_pimpl.
    apply pimpl_star_emp.
Qed.

Lemma flatten_default' : forall AT AEQ V (p : @pred AT AEQ V),
  p <=p=> stars (p :: nil).
Proof.
  firstorder.
Qed.

Lemma flatten_default : forall AT AEQ V (p : @pred AT AEQ V),
  p <=p=> exists (x:unit), stars (p :: nil) * [[True]].
Proof.
  unfold stars; split.
  - apply pimpl_exists_r; exists tt.
    apply sep_star_lift_r.
    split; pred.
  - apply pimpl_exists_l; intros.
    eapply pimpl_trans; [apply sep_star_lift2and|].
    firstorder.
Qed.

Lemma flatten_emp' : forall AT AEQ V, (@emp AT AEQ V) <=p=> stars nil.
Proof.
  firstorder.
Qed.

Lemma flatten_emp : forall AT AEQ V,
  (@emp AT AEQ V) <=p=> exists (x:unit), stars nil * [[True]].
Proof.
  split.
  - apply pimpl_exists_r; exists tt.
    apply sep_star_lift_r.
    firstorder.
  - apply pimpl_exists_l; intros.
    eapply pimpl_trans; [apply sep_star_lift2and|].
    firstorder.
Qed.

Lemma flatten_star' : forall AT AEQ V (p : @pred AT AEQ V) q ps qs,
  p <=p=> stars ps
  -> q <=p=> stars qs
  -> p * q <=p=> stars (ps ++ qs).
Proof.
  intros.
  eapply piff_trans; [eapply piff_star_r; apply H|]; clear H.
  eapply piff_trans; [eapply piff_star_l; apply H0|]; clear H0.
  induction ps.
  - eapply piff_trans; [apply piff_comm; apply emp_star|apply piff_refl].
  - apply piff_comm.
    eapply piff_trans; [apply stars_prepend|].
    eapply piff_trans; [apply piff_star_l; apply piff_comm; apply IHps|].
    eapply piff_trans; [apply piff_comm; apply sep_star_assoc|].
    apply piff_star_r.
    apply piff_comm.
    eapply piff_trans; [eapply stars_prepend|].
    apply piff_refl.
Qed.

Lemma flatten_star : forall AT AEQ V PT QT (p : @pred AT AEQ V) q ps qs P Q,
  p <=p=> (exists (x:PT), stars (ps x) * [[P x]])%pred
  -> q <=p=> (exists (x:QT), stars (qs x) * [[Q x]])%pred
  -> p * q <=p=> exists (x:PT*QT), stars (ps (fst x) ++ qs (snd x)) * [[P (fst x) /\ Q (snd x)]].
Proof.
  intros.
  eapply piff_trans; [eapply piff_star_r; apply H|]; clear H.
  eapply piff_trans; [eapply piff_star_l; apply H0|]; clear H0.
  split.
  - apply pimpl_exists_l_star. apply pimpl_exists_l. intro ePT.
    eapply pimpl_trans; [apply sep_star_comm|].
    apply pimpl_exists_l_star. apply pimpl_exists_l. intro eQT.
    apply pimpl_exists_r. exists (ePT, eQT). simpl.
    eapply pimpl_trans; [apply sep_star_assoc_2|].
    apply sep_star_lift_l; intros.
    eapply pimpl_trans; [apply sep_star_comm|].
    eapply pimpl_trans; [apply sep_star_assoc_2|].
    apply sep_star_lift_l; intros.
    apply sep_star_lift_r.
    apply pimpl_and_split; [|firstorder].
    apply flatten_star'; apply piff_refl.
  - apply pimpl_exists_l. intro e. simpl.
    eapply pimpl_trans; [|apply pimpl_exists_r_star].
    apply pimpl_exists_r. exists (fst e).
    eapply pimpl_trans; [|apply sep_star_comm].
    eapply pimpl_trans; [|apply pimpl_exists_r_star].
    apply pimpl_exists_r. exists (snd e).
    apply sep_star_lift_l; intros.
    eapply pimpl_trans; [|apply sep_star_assoc_1].
    apply sep_star_lift_r.
    apply pimpl_and_split; [|firstorder].
    eapply pimpl_trans; [|apply sep_star_comm].
    eapply pimpl_trans; [|apply sep_star_assoc_1].
    apply sep_star_lift_r.
    apply pimpl_and_split; [|firstorder].
    apply flatten_star'; apply piff_refl.
Qed.

Lemma flatten_exists : forall AT AEQ V T PT (p : _ -> @pred AT AEQ V) ps P,
  (forall ( a : T ), (p a <=p=> exists ( x : PT ), stars (ps a x) * [[ P a x ]]))
  -> (exists ( a : T ), p a) <=p=>
      (exists ( x : ( (VARNAME(dummy)*T) * PT ) ),
       stars (ps (snd (fst x)) (snd x)) *
       [[ P (snd (fst x)) (snd x) ]]).
Proof.
  intros; split.
  - apply pimpl_exists_l; intro eT.
    eapply pimpl_trans; [apply H|].
    apply pimpl_exists_l; intro ePT.
    apply pimpl_exists_r. exists (varname_val, eT, ePT).
    apply pimpl_refl.
  - apply pimpl_exists_l; intro e.
    apply pimpl_exists_r. exists (snd (fst e)).
    eapply pimpl_trans; [|apply H].
    apply pimpl_exists_r. exists (snd e).
    apply pimpl_refl.
Qed.

Lemma flatten_lift_empty: forall AT AEQ V P,
  [[P]] <=p=> (exists (x:unit), stars (@nil (@pred AT AEQ V)) * [[P]]).
Proof.
  split.
  - apply pimpl_exists_r. exists tt. apply emp_star.
  - apply pimpl_exists_l; intros. apply emp_star.
Qed.

Ltac flatten_assign_name good_name :=
  match goal with
  | [ |- (exists lv : (VARNAME(dummy) * ?T) * ?PT, ?body) <=p=> _ ] =>
    set (LHS := (exists lv : (VARNAME(good_name) * T) * PT, body)%pred);
    unfold LHS in *; clear LHS;
    apply piff_refl
  end.

Ltac flatten :=
  repeat match goal with
  | [ |- emp <=p=> _ ] => apply flatten_emp
  | [ |- _ * _ <=p=> _ ] =>
    eapply piff_trans; [ apply flatten_star | apply piff_refl ]
  | [ |- (exists (varname : _), _)%pred <=p=> _ ] =>
    eapply piff_trans; [ apply flatten_exists | flatten_assign_name varname ]; intros ?varname
  | [ |- [[_]] <=p=> _ ] =>
    eapply piff_trans; [ apply flatten_lift_empty | apply piff_refl ]
  | _ => apply flatten_default
  end.

Definition okToUnify {AT AEQ V} (p1 p2 : @pred AT AEQ V) := p1 = p2.

Hint Extern 0 (okToUnify (?p |-> _) (?p |-> _)) => constructor : okToUnify.
Hint Extern 0 (okToUnify (?p |+> _) (?p |+> _)) => constructor : okToUnify.
Hint Extern 0 (okToUnify ?a ?a) => constructor : okToUnify.

(* Try to unify any two [ptsto] predicates.  Since ring does not unify
 * existential variables, this is safe to do; they will be unified only
 * if the addresses in the two [ptsto] predicates are necessarily equal.
 * Fold [wzero] for [ring], and convert nat multiplications and additions
 * into word, so that [ring] can solve them.

Ltac rw_natToWord_mult :=
  match goal with
  | [ |- context[natToWord ?s (?x * ?y)] ] =>
    match x with
    | O => fail 1
    | _ => rewrite natToWord_mult with (sz:=s) (n:=x) (m:=y)
    end
  end.

Ltac rw_natToWord_plus :=
  match goal with
  | [ |- context[natToWord ?s (?x + ?y)] ] =>
    match x with
    | O => fail 1
    | _ => rewrite natToWord_plus with (sz:=s) (n:=x) (m:=y)
    end
  end.

Ltac rw_natToWord_S :=
  match goal with
  | [ |- context[natToWord ?s (S ?x)] ] =>
    match x with
    | O => fail 1
    | _ => rewrite natToWord_S with (sz:=s) (n:=x)
    end
  end.

Ltac ring_prepare :=
  repeat ( rw_natToWord_mult ||
           rw_natToWord_plus ||
           rw_natToWord_S );
  fold (wzero addrlen);
  repeat rewrite natToWord_wordToNat.


Ltac words := ring_prepare; ring.

Ltac wordcmp_one :=
  match goal with
  | [ H: (natToWord ?sz ?n < ?x)%word |- _ ] =>
    assert (goodSize sz (wordToNat x)) by (apply wordToNat_good);
    assert (wordToNat (natToWord sz n) < wordToNat x) by (apply wlt_lt'; unfold goodSize in *; auto; omega);
    clear H
  | [ H: context[wordToNat (natToWord _ _)] |- _ ] =>
    rewrite wordToNat_natToWord_idempotent' in H;
    [| solve [ omega ||
               ( eapply Nat.le_lt_trans; [| apply wordToNat_good ]; eauto ) ] ]
  | [ H: (?a < natToWord _ ?b)%word |- wordToNat ?a < ?b ] =>
    apply wlt_lt in H; unfold goodSize in *; erewrite wordToNat_natToWord_bound in H;
    [ apply H | eauto ]
  | [ H: ?a = wordToNat ?b |- ?a <= wordToNat ?c ] =>
    try solve [ rewrite H; apply le_n ]
  end.


Ltac wordcmp := repeat wordcmp_one.

*)


Inductive pick {AT AEQ V} (lhs : pred) : list (@pred AT AEQ V) -> list pred -> Prop :=
| PickFirst : forall p ps,
  okToUnify lhs p
  -> pick lhs (p :: ps) ps
| PickLater : forall p ps ps',
  pick lhs ps ps'
  -> pick lhs (p :: ps) (p :: ps').

Lemma pick_later_and : forall AT AEQ V (p : @pred AT AEQ V) p' ps ps' (a b : @pred AT AEQ V),
  pick p ps ps' /\ (a =p=> b)
  -> pick p (p' :: ps) (p' :: ps') /\ (a =p=> b).
Proof.
  intuition; apply PickLater; auto.
Qed.

Lemma crash_xform_okToUnify : forall (P Q: rawpred),
  okToUnify P Q -> okToUnify (crash_xform P) (crash_xform Q).
Proof.
  intros. unfold okToUnify in *. congruence.
Qed.


Ltac pick := solve [ repeat 
          ((apply PickFirst;
            solve [ try apply crash_xform_okToUnify; trivial with okToUnify ]
           ) || apply PickLater) ].


Theorem imply_one : forall AT AEQ V qs qs' (p : @pred AT AEQ V) q ps F,
  (pick q qs qs' /\ (p =p=> q))
  -> (stars ps * F =p=> stars qs')
  -> stars (p :: ps) * F =p=> stars qs.
Proof.
  intros. destruct H.
  eapply pimpl_trans. eapply pimpl_sep_star. apply stars_prepend. apply pimpl_refl.
  eapply pimpl_trans. apply sep_star_assoc_1.
  eapply pimpl_trans. eapply pimpl_sep_star. eauto. eauto.
  clear dependent ps.
  induction H; intros.
  - inversion H; subst. apply stars_prepend.
  - eapply pimpl_trans; [|apply stars_prepend].
    eapply pimpl_trans; [|eapply pimpl_sep_star; [apply pimpl_refl|apply IHpick] ].
    eapply pimpl_trans. eapply pimpl_sep_star. eapply pimpl_refl. eapply stars_prepend.
    eapply pimpl_trans; [eapply sep_star_assoc_2|].
    eapply pimpl_trans; [|eapply sep_star_assoc_1].
    eapply pimpl_sep_star. eapply sep_star_comm. eapply pimpl_refl.
Qed.

Theorem cancel_one : forall AT AEQ V qs qs' (p : @pred AT AEQ V) ps F,
  pick p qs qs'
  -> (stars ps * F =p=> stars qs')
  -> stars (p :: ps) * F =p=> stars qs.
Proof.
  intros.
  eapply imply_one; eauto.
Qed.

Ltac cancel_one := eapply cancel_one; [ pick | ].

Theorem delay_one : forall AT AEQ V (p : @pred AT AEQ V) ps q qs,
  (stars ps * stars (p :: qs) =p=> q)
  -> stars (p :: ps) * stars qs =p=> q.
Proof.
  unfold stars; simpl; intros.
  eapply pimpl_trans; [|eauto].
  eapply pimpl_trans. eapply pimpl_sep_star; [|eapply pimpl_refl]. apply stars_prepend.
  eapply pimpl_trans; [|eapply pimpl_sep_star; [apply pimpl_refl|apply stars_prepend] ].
  eapply pimpl_trans; [|eapply sep_star_assoc_1].
  eapply pimpl_sep_star; [|eapply pimpl_refl].
  eapply sep_star_comm.
Qed.

Ltac delay_one := apply delay_one.

Lemma and_imp:
  forall (A B C:Prop),
  (A -> B)
  -> (A /\ C)
  -> (B /\ C).
Proof.
  firstorder.
Qed.

Lemma finish_frame : forall AT AEQ V (p : @pred AT AEQ V),
  stars nil * p =p=> p.
Proof.
  intros. apply star_emp_pimpl.
Qed.

Ltac cancel' := repeat (cancel_one || delay_one);
                try solve [ unfold stars at 2 3; simpl;
                  match goal with
                  | [ |- stars nil * ?P =p=> ?Q] =>
                    match P with
                    | context[sep_star] => match Q with context[sep_star] => fail 2 end
                    | _ => idtac
                    end;
                    simple apply finish_frame
                  end ].

Theorem split_or_one : forall AT AEQ V (q : @pred AT AEQ V) pa pb ps F,
  stars (pa :: ps) * F =p=> q
  -> stars (pb :: ps) * F =p=> q
  -> stars ((pa \/ pb) :: ps) * F =p=> q.
Proof.
  intros.
  eapply pimpl_trans. eapply piff_star_r. eapply piff_comm. apply stars_prepend.
  eapply pimpl_trans. eapply sep_star_assoc.
  eapply pimpl_trans. eapply sep_star_comm.
  eapply pimpl_trans. eapply sep_star_or_distr.
  apply pimpl_or_l.
  - eapply pimpl_trans. eapply sep_star_comm.
    eapply pimpl_trans. eapply sep_star_assoc.
    eapply pimpl_trans. eapply piff_star_r. apply stars_prepend.
    eauto.
  - eapply pimpl_trans. eapply sep_star_comm.
    eapply pimpl_trans. eapply sep_star_assoc.
    eapply pimpl_trans. eapply piff_star_r. apply stars_prepend.
    eauto.
Qed.

Theorem exists_one : forall AT AEQ V T p ps F (q : @pred AT AEQ V),
  (forall a:T, stars (p a :: ps) * F =p=> q)
  -> stars ((exists a:T, p a) :: ps) * F =p=> q.
Proof.
  intros.
  eapply pimpl_trans. eapply piff_star_r. eapply piff_comm. apply stars_prepend.
  eapply pimpl_trans. eapply sep_star_assoc.
  eapply pimpl_exists_l_star.
  eapply pimpl_exists_l; intros.
  eapply pimpl_trans; [| eauto ].
  eapply pimpl_trans. eapply sep_star_assoc.
  eapply pimpl_sep_star; [| eapply pimpl_refl ].
  eapply pimpl_trans. apply stars_prepend.
  apply pimpl_refl.
Qed.

Ltac split_one := match goal with
                  | [ |- stars ((_ \/ _) :: _) * _ =p=> _ ]
                    => apply split_or_one
                  | [ |- stars ((exists _, _)%pred :: _) * _ =p=> _ ]
                    => apply exists_one; intro
                  end.

Ltac split_or_l := repeat ( (repeat split_one) ; delay_one );
                   apply restart_canceling.

Lemma stars_or_left: forall AT AEQ V (a b c : @pred AT AEQ V),
  (a =p=> stars (b :: nil))
  -> (a =p=> stars ((b \/ c) :: nil)).
Proof.
  firstorder.
Qed.

Lemma stars_or_right: forall AT AEQ V (a b c : @pred AT AEQ V),
  (a =p=> stars (c :: nil))
  -> (a =p=> stars ((b \/ c) :: nil)).
Proof.
  firstorder.
Qed.

Ltac destruct_type T :=
  match goal with
  | [ H: T |- _ ] => destruct H
  end.

Ltac destruct_lift' H :=
  match type of H with
  | (?a /\ ?b) =>
    let Hlift0:=fresh in
    let Hlift1:=fresh in
    destruct H as [Hlift0 Hlift1]; destruct_lift' Hlift0; destruct_lift' Hlift1
  | ((sep_star _ _) _) =>
    eapply start_normalizing_apply in H; [| flatten ];
    let H1:=fresh in
    let H2:=fresh in
    unfold stars in H; simpl in H; destruct H as [? H1];
    apply sep_star_lift_apply in H1; destruct H1 as [? H2];
    destruct_lift' H2
  | ((and _ _) _) =>
    eapply start_normalizing_apply in H; [| flatten ];
    let H1:=fresh in
    let H2:=fresh in
    unfold stars in H; simpl in H; destruct H as [? H1];
    apply sep_star_lift_apply in H1; destruct H1 as [? H2];
    destruct_lift' H2
  | ((or _ _) _) =>
    eapply start_normalizing_apply in H; [| flatten ];
    let H1:=fresh in
    let H2:=fresh in
    unfold stars in H; simpl in H; destruct H as [? H1];
    apply sep_star_lift_apply in H1; destruct H1 as [? H2];
    destruct_lift' H2
  | ((exists _, _)%pred _) =>
    eapply start_normalizing_apply in H; [| flatten ];
    let H1:=fresh in
    let H2:=fresh in
    unfold stars in H; simpl in H; destruct H as [? H1];
    apply sep_star_lift_apply in H1; destruct H1 as [? H2];
    destruct_lift' H2
  | _ => idtac
  end.

(* XXX it could be faster to avoid [simpl in *] by explicitly doing
 * destruct_prod / destruct_type in each case of [destruct_lift']
 * and then doing [simpl in H] on specific hypotheses. *)
Ltac destruct_lift H :=
  destruct_lift' H;
  destruct_pairs;
  simpl in *;
  repeat destruct_type True;
  repeat destruct_type unit;
  simpl in *;
  repeat clear_varname.

Ltac destruct_lifts := try progress match goal with 
  | [ H : sep_star _ _  _ |- _ ] => destruct_lift H
end.

Definition norm_goal (T: Type) (g: T) := True.
Theorem norm_goal_ok: forall T g, @norm_goal T g. Proof. firstorder. Qed.
Opaque norm_goal.

Ltac clear_norm_goal :=
  match goal with
  | [ H: norm_goal _ |- _ ] => clear H
  end.

Ltac set_norm_goal :=
  match goal with
  | [ |- ?g ] => repeat clear_norm_goal; assert (norm_goal g) by apply norm_goal_ok
  end.

(* The goal of pimpl_hidden is to prevent "auto with norm_hint_right" from
 * solving things automatically for us, unless we have an explicit hint..
 *)
Definition pimpl_hidden := @pimpl.
Infix "=!=>" := pimpl_hidden (at level 90).
Arguments pimpl_hidden {AT AEQ V} _ _.
Theorem pimpl_hide: forall AT AEQ V (a b : @pred AT AEQ V), (pimpl_hidden a b) -> (pimpl a b).
Proof. auto. Qed.
Theorem pimpl_unhide: forall AT AEQ V (a b : @pred AT AEQ V), (pimpl a b) -> (pimpl_hidden a b).
Proof. auto. Qed.
Opaque pimpl_hidden.

(**
 * In-code hints to transform predicates.
 *)
(*
Definition xform_fwd {T: Prop} (x: T) := True.
Definition xform_bwd {T: Prop} (x: T) := True.
Opaque xform_fwd xform_bwd.

Definition Xform {T} {TFWD TBWD : Prop} (fwd : TFWD) (bwd : TBWD) p : prog T :=
  p.

Theorem xform_ok : forall T p (TF TB:Prop) (tf:TF) (tb:TB) (rx:prog T), {{p}} rx
  -> {{p}} Xform tf tb rx.
Proof.
  auto.
Qed.

Ltac clear_xform := repeat match goal with
  | [ H: xform_fwd _ |- _ ] => clear H
  | [ H: xform_bwd _ |- _ ] => clear H
  end.

Ltac remember_xform := try match goal with
  | [ |- {{_}} Xform ?fwd ?bwd _ ] =>
    clear_xform;
    assert (xform_fwd fwd) by constructor;
    assert (xform_bwd bwd) by constructor;
    apply xform_ok
  end.

Ltac apply_xform canceller := match goal with
  | [ |- _ =p=> ?rhs ] => match goal with
    | [ H: _ =p=> rhs |- _ ] => match goal with
      | [ Hx: xform_bwd ?bwd |- _ ] => pimpl_crash;
        clear_xform;
        eapply pimpl_trans; [| eapply pimpl_trans;
        [ apply pimpl_sep_star; [ apply pimpl_refl | apply bwd ] | ] ];
        [ try canceller .. ]
        || fail 3
      | _ => idtac
      end
    | _ => match goal with
      | [ Hx: xform_fwd ?fwd |- _ ] =>
        clear_xform;
        eapply pimpl_trans; [| eapply pimpl_trans;
        [ apply pimpl_sep_star; [ apply pimpl_refl | apply fwd ] | ] ];
        [ try canceller .. ]
        || fail 3
      | _ => idtac
      end
    end
  | _ => idtac
  end; clear_xform.
*)

(**
 * Older predicate replacement machinery.
 *)

Theorem replace_left : forall AT AEQ V ps ps' q (p : @pred AT AEQ V) p' F,
  pick p ps ps' /\ (p =p=> p')
  -> (stars (p' :: ps') * F =p=> q)
  -> (stars ps * F =p=> q).
Proof.
  intros; destruct H.
  eapply pimpl_trans; [|apply H0].
  apply pimpl_sep_star; [|apply pimpl_refl].
  clear dependent q.
  induction H; intros.
  - inversion H; subst.
    eapply pimpl_trans; [apply stars_prepend|].
    eapply pimpl_trans; [|apply stars_prepend].
    eapply pimpl_sep_star; auto.
  - eapply pimpl_trans; [apply stars_prepend|].
    eapply pimpl_trans; [|apply stars_prepend].
    eapply pimpl_trans; [|apply pimpl_sep_star; [apply pimpl_refl|apply stars_prepend] ].
    eapply pimpl_trans; [|apply sep_star_assoc].
    eapply pimpl_trans; [|apply pimpl_sep_star; [apply sep_star_comm|apply pimpl_refl] ].
    eapply pimpl_trans; [|apply sep_star_assoc].
    eapply pimpl_sep_star; auto.
    eapply pimpl_trans; [|apply stars_prepend].
    auto.
Qed.

Theorem replace_right : forall AT AEQ V ps ps' q (p : @pred AT AEQ V) p',
  pick p ps ps' /\ (p' =p=> p)
  -> (q =p=> stars (p' :: ps'))
  -> (q =p=> stars ps).
Proof.
  intros; destruct H.
  eapply pimpl_trans; [apply H0|].
  clear dependent q.
  induction H; intros.
  - inversion H; subst.
    eapply pimpl_trans; [|apply stars_prepend].
    eapply pimpl_trans; [apply stars_prepend|].
    eapply pimpl_sep_star; auto.
  - eapply pimpl_trans; [|apply stars_prepend].
    eapply pimpl_trans; [apply stars_prepend|].
    eapply pimpl_trans; [apply pimpl_sep_star; [apply pimpl_refl|apply stars_prepend]|].
    eapply pimpl_trans; [apply sep_star_assoc|].
    eapply pimpl_trans; [apply pimpl_sep_star; [apply sep_star_comm|apply pimpl_refl]|].
    eapply pimpl_trans; [apply sep_star_assoc|].
    eapply pimpl_sep_star; auto.
    eapply pimpl_trans; [apply stars_prepend|].
    auto.
Qed.

Ltac replace_left_one := split; [ apply PickFirst; constructor
                                | apply pimpl_hide; auto with norm_hint_left ].

Ltac replace_right_one := split; [ apply PickFirst; constructor
                                 | apply pimpl_hide; auto with norm_hint_right ].

Ltac replace_left := eapply replace_left;
  [ solve [ repeat ( solve [ replace_left_one ] || apply pick_later_and ) ] | ].

Ltac replace_right := eapply replace_right;
  [ solve [ repeat ( solve [ replace_right_one ] || apply pick_later_and ) ] | ].

(* XXX ask Adam: should we replace norm_hint_left / norm_hint_write with
 * setoid-based rewriting?  might be too early: setoid rewriting is still
 * a bit buggy in Coq..
 *)

Ltac norm'l := eapply start_normalizing_left; [ flatten | ];
               eapply pimpl_exists_l; intros;
               apply sep_star_lift_l; let Hlift:=fresh in intro Hlift;
               destruct_lift Hlift.

Ltac norm'r := eapply start_normalizing_right; [ flatten | ];
               eapply pimpl_exists_r; repeat eexists_one;
               apply sep_star_lift_r; apply pimpl_and_lift;
               simpl in *.

Create HintDb false_precondition_hint.


Ltac destruct_pair_eq :=
    match goal with
    | [ H : (_ , _) = (_, _) |- _ ] => inversion H; clear H
    end.

Ltac norml := unfold pair_args_helper;
             norm'l; repeat deex; repeat destruct_type valuset;
             repeat destruct_pair_eq;
             (* To check whether [split_or_l] succeeded, we require that it
              * produce at least 2 subgoals.  Also, because [split_or_l] reverses
              * the list of predicates, we run it twice to preserve the order.
              *)
             repeat ( split_or_l; [ | | .. ]; split_or_l; unfold stars; simpl; norm'l );
             set_norm_goal;
             repeat ( replace_left; unfold stars; simpl; set_norm_goal; norm'l ).

Ltac norm := norml;
             solve [ exfalso ; auto with false_precondition_hint ] ||
             ( norm'r; [ try ( replace_right; unfold stars; simpl; norm ) | .. ] );
             repeat clear_norm_goal.

Ltac inv_option_eq' := repeat match goal with
  | [ H: None = None |- _ ] => clear H
  | [ H: None = Some _ |- _ ] => inversion H
  | [ H: Some _ = None |- _ ] => inversion H
  | [ H: Some _ = Some _ |- _ ] => inversion H; clear H
  | [ H: (_, _) = (_, _) |- _ ] => inversion H; clear H
  end.

Ltac inv_option_eq := try ((progress inv_option_eq'); subst; eauto).

Tactic Notation "denote" open_constr(pattern) "as" ident(n) :=
  match goal with | [ H: context [ pattern ] |- _ ] => rename H into n end.

Tactic Notation "denote!" open_constr(pattern) "as" ident(n) :=
  match goal with | [ H: pattern |- _ ] => rename H into n end.

Tactic Notation "substl" :=
  subst; repeat match goal with
  | [ H : ?l = ?r |- _ ] => is_var l;
    match goal with
     | [ |- context [ r ] ] => idtac
     | _ => setoid_rewrite H
    end
  end.

Tactic Notation "substl" constr(term) "at" integer_list(pos) :=
  match goal with
  | [ H : term = _  |- _ ] => setoid_rewrite H at pos
  | [ H : _ = term  |- _ ] => setoid_rewrite <- H at pos
  end.

Tactic Notation "substl" constr(term) :=
  match goal with
  | [ H : term = _  |- _ ] => setoid_rewrite H
  | [ H : _ = term  |- _ ] => setoid_rewrite <- H
  end.


Ltac safecancel :=
  intros;
  unfold stars; simpl; try subst;
  pimpl_crash;
  norm;
  try match goal with
      | [ |- _ =p=> stars ((_ \/ _) :: nil) ] =>
        solve [ apply stars_or_left; safecancel
              | apply stars_or_right; safecancel ]
      | [ |- _ =p=> _ ] => cancel'
      end;
  set_evars; intuition; subst_evars;
  try ( pred_apply; safecancel );
  try congruence;
  unfold stars; simpl; inv_option_eq;
  try match goal with
  | [ |- emp * _ =p=> _ ] => eapply pimpl_trans; [ apply star_emp_pimpl |]
  end.

Ltac cancel_with' t intuition_t :=
  intros;
  unfold stars; simpl; try subst;
  pimpl_crash;
  norm;
  try match goal with
      | [ |- _ =p=> stars ((_ \/ _) :: nil) ] =>
        solve [ apply stars_or_left; cancel_with' t intuition_t
              | apply stars_or_right; cancel_with' t intuition_t ]
      | [ |- _ =p=> _ ] => cancel'
      end;
  intuition intuition_t;
  try ( pred_apply; cancel_with' t intuition_t);
  try congruence;
  try t;
  unfold stars; simpl; inv_option_eq;
  try match goal with
  | [ |- emp * _ =p=> _ ] => eapply pimpl_trans; [ apply star_emp_pimpl |]
  end.

Ltac cancel_with t := cancel_with' t auto.
Ltac cancel := cancel_with idtac.

(* fastest version of cancel, should always try this first *)
Ltac cancel_exact := repeat match goal with 
  | [ |- (?a =p=> ?a)%pred ] =>
        eapply pimpl_refl
  | [ |- (_ * ?a =p=> _ * ?a)%pred ] =>
        eapply pimpl_sep_star; [ | eapply pimpl_refl]
  | [ |- ( ?a * _ =p=> ?a * _)%pred ] =>
        eapply pimpl_sep_star; [ eapply pimpl_refl | ]
  | [ |- ( ?a * _ =p=> _ * ?a)%pred ] =>
        rewrite sep_star_comm1
  | [ |- ( (?a * _) * _ =p=> ?a * _)%pred ] =>
        rewrite sep_star_assoc_1
end.


Ltac cancel_by H :=
  eapply pimpl_ext; [ eapply H | cancel | cancel ].


Theorem nop_ok :
  forall T A v (rx : A -> prog T),
  {{ fun hm done_ crash_ => exists F, F * [[ forall r_,
    {{ fun hm' done' crash' => (fun r => F * [[ r = v ]]) r_ *
                           [[ hm = hm' ]] *
                           [[ done' = done_ ]] * [[ crash' = crash_ ]]}}
     rx r_ ]] * [[ F =p=> crash_ hm]] }} rx v.
Proof.
  unfold corr2, pimpl.
  intros.
  destruct H.
  destruct_lift H.
  eapply H4; eauto.
  pred_apply.
  cancel.
Qed.

Ltac autorewrite_fast_goal :=
  set_evars; (rewrite_strat (topdown (hints core))); subst_evars;
  try autorewrite_fast_goal.

Ltac autorewrite_fast :=
  match goal with
  | [ H: _ |- _ ] =>
    set_evars_in H; (rewrite_strat (topdown (hints core)) in H); subst_evars;
    [ try autorewrite_fast | try autorewrite_fast_goal .. ]
  | [ |- _ ] => autorewrite_fast_goal
  end.

Ltac destruct_branch :=
  match goal with
  | [ |- {{ _ }} match ?v with | Some _ => _ | None => _ end ] => destruct v eqn:?
  | [ |- {{ _ }} match ?v with | None => _ | Some _ => _ end ] => destruct v eqn:?
  | [ |- {{ _ }} if ?v then _ else _ ] => destruct v eqn:?
  | [ |- {{ _ }} let '_ := ?v in _ ] => destruct v eqn:?
  end.

Ltac prestep :=
  intros;
  try autounfold with hoare_unfold in *;
  repeat destruct_pair_once;
  try cancel;
  repeat destruct_branch;
  (*   remember_xform; *)
  monad_simpl;
  ((eapply pimpl_ok2; [ solve [ eauto with prog ] | ])
   || (eapply pimpl_ok2_cont; [ solve [ eauto with prog ] | | ])
   || (eapply pimpl_ok3; [ solve [ eauto with prog ] | ])
   || (eapply pimpl_ok3_cont; [ solve [ eauto with prog ] | | ])
   || (eapply pimpl_ok2; [
        match goal with
        | [ |- {{ _ }} ?a _ ] => is_var a
        end; solve [ eapply nop_ok ] | ]));
  intros; try subst;
  repeat destruct_type unit;  (* for returning [unit] which is [tt] *)
  try autounfold with hoare_unfold in *; eauto.

Ltac poststep t :=
  let tac := match goal with
  | [ |- corr2 _ _ ] => idtac
  | _ => t
  end in
  intuition tac;
  try omega;
  try congruence;
  try tac.

Ltac safestep :=
    prestep; safecancel;
    set_evars; poststep auto; subst_evars.

Ltac or_r := apply pimpl_or_r; right.
Ltac or_l := apply pimpl_or_r; left.


Tactic Notation "step" "using" tactic(t) "with" ident(db) "in" "*" :=
  prestep;
  try ( cancel_with t ; try ( autorewrite with db in * |-; cancel_with t ) );
  poststep t.

Tactic Notation "step" "using" tactic(t) "with" ident(db) :=
  prestep;
  try ( cancel_with t ; try ( autorewrite with db; cancel_with t ) );
  poststep t.

Tactic Notation "step" "using" tactic(t) "with" "intuition" tactic(intuition_t) :=
  prestep;
  try (cancel_with' t intuition_t; try cancel_with' t intuition_t);
  poststep t.

Tactic Notation "step" "using" tactic(t) :=
  prestep;
  try (cancel_with t; try cancel_with t);
  poststep t.


(*
Ltac step_with t :=
  prestep;
  try ( cancel_with t ; try ( progress autorewrite_fast ; cancel_with t ) );
  apply_xform cancel;
  try cancel_with t; try autorewrite_fast;
  intuition t;
  try omega;
  try congruence;
  try t.
*)

Ltac step := step using eauto.
Ltac step_idtac := step using idtac with intuition idtac.

Tactic Notation "hoare" "using" tactic(t) "with" ident(db) "in" "*" :=
  repeat (step using t with db in *).

Tactic Notation "hoare" "using" tactic(t) "with" ident(db) :=
  repeat (step using t with db).

Tactic Notation "hoare" "using" tactic(t) :=
  repeat (step using t).

Ltac hoare := hoare using eauto.



Ltac xform_deex_r :=
    match goal with
    | [ |- pimpl _ (crash_xform (exis _)) ] =>
            rewrite crash_xform_exists_comm;
            apply pimpl_exists_r; eexists
    end.


Ltac xform_deex_l :=
    norml; unfold stars; simpl; clear_norm_goal;
    try rewrite -> crash_xform_exists_comm;
    try (rewrite sep_star_comm, star_emp_pimpl);
    try match goal with
    | [ |- pimpl (exis _) _ ] => apply pimpl_exists_l; intro
    end.

Ltac xform_dist :=
  rewrite crash_xform_sep_star_dist ||
  rewrite crash_xform_or_dist ||
  rewrite crash_xform_lift_empty ||
  rewrite crash_invariant_emp ||
  rewrite <- crash_invariant_emp_r.

Ltac xform_norml :=
  repeat (xform_deex_l || xform_dist).

Ltac xform_normr :=
  repeat (xform_deex_r || xform_dist).

Ltac xform_norm :=
  xform_norml; xform_normr.

Ltac xcrash_rewrite :=
  match goal with
  | [ H : forall rc hm, (crash_xform rc =p=> crash_xform ?x) -> _ =p=> ?c hm |- _ =p=> ?c ?hm] =>
      eapply pimpl_trans; [ | eapply H ]; cancel; subst
  | [ H : crash_xform ?rc =p=> _ |- crash_xform ?rc =p=> _ ] => rewrite H
  end.

Ltac xcrash := subst; repeat xcrash_rewrite;
               xform_norm; cancel; xform_normr; cancel.

