signature CTT =
sig
  structure Syntax : ABT
  type name = Syntax.Variable.t
  type term = Syntax.t

  structure Conv : CONV where type term = term

  type world
  type label
  type tactic

  structure Rules : sig
    (* Pretend you have got a proof. *)
    val Admit : tactic

    (* H >> A = B ∈ U{l} by Cum k (k < l)
     * 1.  H >> A = B ∈ U{k}
     *)
    val Cum : Level.t option -> tactic

    (* H >> U{l} = U{l} ∈ U{k} by UnivEq (l < k) *)
    val UnivEq : tactic

    (* H >> Void = Void ∈ U{k} by VoidEq *)
    val VoidEq : tactic

    (* H >> (M = N ∈ A) = (M' = N' ∈ A') ∈ U{k}
     * 1. H >> A = A' ∈ U{k}
     * 2. H >> M = M' ∈ A
     * 3. H >> N = N' ∈ A *)
    val EqEq : tactic

    (* H >> A by VoidElim
     * 1. H >> Void
     *)
    val VoidElim : tactic

    (* H >> Unit = Unit ∈ U{k} by UnitEq *)
    val UnitEq : tactic

    (* H >> Unit by UnitIntro *)
    val UnitIntro : tactic

    (* H, x : Unit, H'[x] >> P by UnitElim x
     * 1. H, x : Unit, H'[Ax] >> P[Ax]
     *)
    val UnitElim : int -> tactic

    (* H >> Ax = Ax ∈ Unit *)
    val AxEq : tactic

    (* H >> (Σx:A)B[x] = (Σx:A')B'[x] ∈ U{k} by ProdEq z
     * 1. H >> A = A' ∈ U{k}
     * 2. H, z : A >> B[z] = B'[z] ∈ U{k}
     *)
    val ProdEq : name option -> tactic

    (* H >> (Σx:A)B[x] by ProdIntro M
     * 1. H >> M ∈ A
     * 2. H >> B[M]
     * 3. H, x:A >> B[x] ∈ U{k}
     *)
    val ProdIntro : term * name option * Level.t option -> tactic
    val IndependentProdIntro : tactic

    (* H, z : (Σx:A)B[x], H'[z] >> P[z] by ProdElim z (s, t)
     * H, z : (Σx:A)B[x], s : A, t : B[s], H'[<s,t>] >> P[<s,t>]
     *)
    val ProdElim : int * (name * name) option -> tactic

    val PairEq : name option * Level.t option -> tactic
    val SpreadEq : term option * term option * (name * name * name) option -> tactic

    val FunEq : name option -> tactic
    val FunIntro : name option * Level.t option -> tactic
    val FunElim : int * term * (name * name) option -> tactic
    val LamEq : name option * Level.t option -> tactic
    val ApEq : term option -> tactic
    val FunExt : name option * Level.t option -> tactic

    val IsectEq : name option -> tactic
    val IsectIntro : name option * Level.t option -> tactic
    val IsectElim : int * term * (name * name) option -> tactic
    val IsectMemberEq : name option * Level.t option -> tactic
    val IsectMemberCaseEq : term option * term -> tactic

    val SubsetEq : name option -> tactic
    val SubsetIntro : term * name option * Level.t option -> tactic
    val IndependentSubsetIntro : tactic
    val SubsetElim : int * (name * name) option -> tactic
    val SubsetMemberEq : name option * Level.t option -> tactic

    val MemCD : tactic
    val Witness : term -> tactic

    val Assumption : tactic
    val Hypothesis : int -> tactic
    val HypEq : tactic
    val EqInSupertype : tactic

    val Unfold : world * label -> tactic
    val Unfolds : world * (label list) -> tactic
    val Lemma : world * label -> tactic

    val RewriteGoal : Conv.conv -> tactic

    val EqSubst : term * term * Level.t option -> tactic
    val EqSym : tactic

    datatype dir = LEFT | RIGHT
    val HypEqSubst : dir * int * term * Level.t option -> tactic
  end

  structure Conversions :
  sig
    val ApBeta : Conv.conv
    val SpreadBeta : Conv.conv
  end
end
