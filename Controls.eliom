{shared{
  open Eliom_content.Html5.D
  external (|>): 'a -> ('a -> 'b) -> 'b = "%revapply"
}}

{client{
  open Eliom_content.Html5
  open Printf
  let firelog s = Firebug.console##log (Js.string s)

  let template_hack (maxexp,descr,_) =
    div ~a:[a_class ["suggestion-item"]]
      [ span ~a:[a_class ["post_tag"]]
          [ span ~a:[a_class ["match"]] [pcdata descr]
          ]
      ; br ()
      ; span ~a:[a_style "item-multiplier"] [pcdata (sprintf "≤ %s" (Int32.to_string maxexp))]
      ]

}}

(* It should look like
 * http://ocsigen.org/darcsweb/?r=ocsimore;a=headblob;f=/src/site/user_widgets.eliom#l45
 *)
let text_with_suggestions ~container get_suggestions template =
  ignore {unit{
    let open Lwt in
    async (fun () ->
     %get_suggestions "Some string" >>= fun suggestions ->
     (* If we use this line --- no crash *)
     (* let divs = List.map template_hack  suggestions in*)
     (* Whe we use server function -- it crashes in appendChild *)
     let divs = List.map %template suggestions in
     let () = firelog (sprintf "divs count = %d" (List.length divs)) in
     let () =
       try
       (* After next line crash appears
        * TypeError: Cannot read property '0' of undefined *)
         Eliom_content.Html5.Manip.replaceAllChild %container divs
       with exn ->
         firelog (sprintf "PIZDA %s" (Printexc.to_string exn) )
     in
     firelog "finished";
     Lwt.return ()
    )
  }}
