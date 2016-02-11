Require Export heap_lang.derived.

Delimit Scope lang_scope with L.
Bind Scope lang_scope with expr val.
Arguments wp {_ _} _ _%L _.

Coercion LitInt : Z >-> base_lit.
Coercion LitBool : bool >-> base_lit.
(** No coercion from base_lit to expr. This makes is slightly easier to tell
   apart language and Coq expressions. *)
Coercion Var : string >-> expr.
Coercion App : expr >-> Funclass.
Coercion of_val : val >-> expr.

(** Syntax inspired by Coq/Ocaml. Constructions with higher precedence come
    first. *)
(* We have overlapping notation for values and expressions, with the expressions
   coming first. This way, parsing as a value will be preferred. If an expression
   was needed, the coercion of_val will be called. *)
(* What about Arguments for hoare triples?. *)
Notation "' l" := (Lit l) (at level 8, format "' l") : lang_scope.
Notation "' l" := (LitV l) (at level 8, format "' l") : lang_scope.
Notation "! e" := (Load e%L) (at level 10, format "! e") : lang_scope.
Notation "'ref' e" := (Alloc e%L) (at level 30) : lang_scope.
Notation "- e" := (UnOp MinusUnOp e%L) (at level 35, right associativity) : lang_scope.
Notation "e1 + e2" := (BinOp PlusOp e1%L e2%L)
  (at level 50, left associativity) : lang_scope.
Notation "e1 - e2" := (BinOp MinusOp e1%L e2%L)
  (at level 50, left associativity) : lang_scope.
Notation "e1 ≤ e2" := (BinOp LeOp e1%L e2%L) (at level 70) : lang_scope.
Notation "e1 < e2" := (BinOp LtOp e1%L e2%L) (at level 70) : lang_scope.
Notation "e1 = e2" := (BinOp EqOp e1%L e2%L) (at level 70) : lang_scope.
Notation "~ e" := (UnOp NegOp e%L) (at level 75, right associativity) : lang_scope.
(* The unicode ← is already part of the notation "_ ← _; _" for bind. *)
Notation "e1 <- e2" := (Store e1%L e2%L) (at level 80) : lang_scope.
Notation "'rec:' f x := e" := (Rec f x e%L)
  (at level 102, f at level 1, x at level 1, e at level 200) : lang_scope.
Notation "'rec:' f x := e" := (RecV f x e%L)
  (at level 102, f at level 1, x at level 1, e at level 200) : lang_scope.
Notation "'if' e1 'then' e2 'else' e3" := (If e1%L e2%L e3%L)
  (at level 200, e1, e2, e3 at level 200) : lang_scope.

(** Derived notions, in order of declaration. The notations for let and seq
are stated explicitly instead of relying on the Notations Let and Seq as
defined above. This is needed because App is now a coercion, and these
notations are otherwise not pretty printed back accordingly. *)
Notation "λ: x , e" := (Lam x e%L)
  (at level 102, x at level 1, e at level 200) : lang_scope.
Notation "λ: x , e" := (LamV x e%L)
  (at level 102, x at level 1, e at level 200) : lang_scope.
Notation "'let:' x := e1 'in' e2" := (Lam x e2%L e1%L)
  (at level 102, x at level 1, e1, e2 at level 200) : lang_scope.
Notation "e1 ;; e2" := (Lam "" e2%L e1%L)
  (at level 100, e2 at level 200) : lang_scope.
