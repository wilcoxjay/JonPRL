functor CEqRules(Utils : RULES_UTIL) : CEQ_RULES =
struct
  open Utils
  open Goal Sequent Syntax CttCalculus Derivation Conversionals Conv

  infix $ \ BY ^!
  infix 3 >>
  infix 2 |:
  infix 8 $$ // @@
  infixr 8 \\

  fun Eq (_ |: H >> P) =
    let
      val #[M, N, U] = P ^! EQ
      val (UNIV _, _) = asApp U
      val #[L, R] = M ^! CEQUAL
      val #[L', R'] = N ^! CEQUAL
    in
      [ MAIN |: H >> C.`> CEQUAL $$ #[L, L']
      , MAIN |: H >> C.`> CEQUAL $$ #[R, R']
      ] BY (fn [D, E] => D.`> CEQUAL_EQ $$ #[D, E]
             | _ => raise Refine)
    end

  fun MemEq (_ |: H >> P) =
    let
      val #[M, N, E] = P ^! EQ
      val #[] = M ^! AX
      val #[] = N ^! AX
      val #[_, _] = E ^! CEQUAL
    in
      [ MAIN |: H >> E
      ] BY mkEvidence CEQUAL_MEMBER_EQ
    end

  fun Sym (_ |: H >> P) =
    let
      val #[M, N] = P ^! CEQUAL
    in
      [ MAIN |: H >> C.`> CEQUAL $$ #[N, M]
      ] BY (fn [D] => D.`> CEQUAL_SYM $$ #[D]
             | _ => raise Refine)
    end

  fun Step (_ |: H >> P) =
    let
      val #[M, N] = P ^! CEQUAL
      val M' =
          case Semantics.step M handle Semantics.Stuck _ => raise Refine of
              Semantics.STEP M' => M'
            | Semantics.CANON => raise Refine
            | Semantics.NEUTRAL => raise Refine
    in
      [ MAIN |: H >> C.`> CEQUAL $$ #[M', N]
      ] BY (fn [D] => D.`> CEQUAL_STEP $$ #[D]
             | _ => raise Refine)
    end

  fun Approx (_ |: H >> P) =
    let
      val #[M, N] = P ^! CEQUAL
    in
      [ MAIN |: H >> C.`> APPROX $$ #[M, N]
      , MAIN |: H >> C.`> APPROX $$ #[N, M]
      ] BY mkEvidence CEQUAL_APPROX
    end

  fun Elim (hyp, onames) (_ |: H >> C) =
    let
      val z = eliminationTarget hyp (H >> C)
      val #[M,N] = Context.lookup H z ^! CEQUAL
      val (a,b) =
        case onames of
             SOME names => names
           | NONE =>
               (Context.fresh (H, Variable.named "a"),
                Context.fresh (H, Variable.named "b"))
      val H' = H @@ (a, C.`> APPROX $$ #[M,N]) @@ (b, C.`> APPROX $$ #[N,M])
    in
      [ MAIN |: H' >> C
      ] BY (fn [D] => D.`> CEQUAL_ELIM $$ #[``z, a \\ b \\ D]
             | _ => raise Refine)
    end

  fun Subst (eq, oxC) (_ |: H >> P) =
    let
      val eq = Context.rebind H eq
      val #[M, N] = eq ^! CEQUAL

      val P' =
        case oxC of
             SOME xC =>
             let
               val fvs = List.map #1 (Context.listItems H)
               val meta = convertToPattern (H, xC // M)
               val solution = Unify.unify (meta, Meta.convert P)
               val x \ C = out xC
               val xC = x \\ applySolution solution (P, convertToPattern (H, C))
               val _ = unify P (xC // M)
             in
               xC // N
             end
           | NONE => CDEEP (fn M' => if Syntax.eq (M,M') then N else raise Conv) P
    in
      [ AUX |: H >> eq
      , MAIN |: H >> P'
      ] BY (fn [D, E] => D.`> CEQUAL_SUBST $$ #[D, E]
             | _ => raise Refine)
    end

  local
    structure Tacticals = Tacticals (Lcf)
    open Tacticals
    infix THEN THENL
  in
    fun HypSubst (dir, hyp, xC) (goal as _ |: H >> P) =
      let
        val z = eliminationTarget hyp (H >> P)
        val X = Context.lookup H z
      in
        case dir of
            Dir.RIGHT =>
            (Subst (X, xC) THENL [Hypothesis_ z, ID]) goal
          | Dir.LEFT =>
            let
              val #[M,N] = X ^! CEQUAL
            in
              (Subst (C.`> CEQUAL $$ #[N,M], xC)
                 THENL [Sym THEN Hypothesis_ z, ID]) goal
            end
      end
  end

  local
    (* Create a new subgoal by walking along the pairs
     * of terms and unbind each term together. As we go
     * we add the new variables to the context as we go
     * and keep track of all the variables we bind.
     *
     * In the end you get a new goal and a list of variables in the
     * order that they were created.
     *)
    fun newSubGoal H vs (t1, t2) =
      case (out t1, out t2) of
          (x \ t1', y \ t2') =>
          newSubGoal (H @@ (x, C.`> BASE $$ #[]))
                     (x :: vs)
                     (t1', subst (``x) y t2')
        | (_, _) =>
          (List.rev vs, MAIN |: H >> C.`> CEQUAL $$ #[t1, t2])

    fun toList v = Vector.foldr op:: nil v

    (* Each derivation needs to bind the variables from the
     * context so all we do is take a vector of lists of variables
     * and a vector of terms and bind all the variables in one list
     * in the corresponding term.
     *)
    fun bindVars vars terms =
      let
        fun go [] t = t
          | go (v :: vs) t = go vs (v \\ t)
      in
        Vector.tabulate (Vector.length terms,
                         fn i => go (Vector.sub (vars, i))
                                    (Vector.sub (terms, i)))
      end
   in
     fun Struct (_ |: H >> P) =
       let
         val #[M, N] = P ^! CEQUAL
         val (oper, subterms) = asApp M
         val subterms' = N ^! oper
         val pairs =
             Vector.tabulate (Vector.length subterms,
                              (fn i => (Vector.sub(subterms, i),
                                        Vector.sub(subterms', i))))
         val (boundVars, subgoals) =
             ListPair.unzip (toList (Vector.map (newSubGoal H []) pairs))
         val boundVars = Vector.fromList boundVars
       in
         subgoals BY (fn Ds =>
                         D.`> (CEQUAL_STRUCT (Vector.map List.length boundVars))
                           $$ bindVars boundVars (Vector.fromList Ds)
                         handle _ => raise Refine)
       end
   end
end
