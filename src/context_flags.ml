#directory "+compiler-libs";;
#load "ocamlcommon.cma";;

let backends =
  try
    let be = Sys.getenv "MCCS_BACKENDS" in
    let bel = String.length be in
    let rec aux i =
      if i >= bel then [] else
      try
        let j = String.index_from be i ' ' in
        String.sub be i (j - i) :: aux (j+1)
      with Not_found -> [String.sub be i (String.length be - i)]
    in List.filter (( <> ) "") (aux 0)
  with Not_found -> ["GLPK"]

let useGLPK = List.mem "GLPK" backends
let useSYM = List.mem "SYMPHONY" backends
let useCBC = List.mem "CBC" backends
let useCLP = List.mem "CLP" backends || useCBC
let useCOIN = useCLP || useCBC || useSYM

let ifc c x = if c then x else []

let cxxflags =
  let flags =
    (if (Sys.win32 && Config.ccomp_type = "msvc")
     then ["\"/EHsc\""]
     else ["-Wall -Wextra -Wno-unused-parameter"]) @
    (ifc useGLPK ["-DUSEGLPK"]) @
    (ifc useCOIN ["-DUSECOIN"]) @
    (ifc useCLP  ["-DUSECLP"]) @
    (ifc useCBC  ["-DUSECBC"]) @
    (ifc useSYM  ["-DUSESYM"])
  in
  "(" ^ String.concat " " flags ^ ")"

let flags =
  let flags =
    ["-lstdc++"] @
    (ifc useCOIN ["-lCoinUtils"]) @
    (ifc useCLP  ["-lOsiClp"]) @
    (ifc useCBC  ["-lOsiCbc";"-lCbc"]) @
    (ifc useSYM  ["-lgomp";"-lOsiSym"])
  in
  let flags = List.map (fun fl -> "(-cclib \"" ^ fl ^ "\")") flags in
  "(" ^ String.concat " " flags ^ ")"

let write f s =
  let oc = open_out f in
  output_string oc s;
  close_out oc

let () =
  write "cxxflags.sexp" cxxflags;
  write "flags.sexp" flags
