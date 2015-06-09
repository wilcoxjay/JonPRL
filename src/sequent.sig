signature SEQUENT =
sig
  type term

  structure Context : CONTEXT
  type name = Context.name
  type context = term Context.context

  datatype sequent = >> of context * term

  val eq : sequent * sequent -> bool
  val to_string : sequent -> string
end
