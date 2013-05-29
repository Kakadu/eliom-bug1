{shared{
  open Eliom_content.Html5.D
  external (|>): 'a -> ('a -> 'b) -> 'b = "%revapply"
}}

{client{
  open Eliom_content.Html5
  open Printf
  let hide_elt e = Eliom_content.Html5.Manip.SetCss.display e "none"
  let show_elt e = Eliom_content.Html5.Manip.SetCss.display e "block"
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

let text_with_suggestions ~container ~name ~attribs get_suggestions template =
  let ans = string_input ~name ~a:attribs ~input_type:`Text () in

  let (_: unit Eliom_lib.client_value) = {{
    let my_input = To_dom.of_input %ans in
	let container = %container in
	let get_suggestions = %get_suggestions in

    let _ =
      lwt suggestions = get_suggestions (my_input##value) in
        (* If we use this line --- no crash *)
        (* let divs = List.map template_hack  suggestions in*)
        (* Whe we use server function -- it crashes in appendChild *)
        let divs = List.map %template suggestions in

        firelog (sprintf "divs count = %d" (List.length divs));
        divs |> List.iter (fun d ->
          firelog "adding div";
          let (_: _ Eliom_content_core.Html5.elt) = d in
          try
            (* After next line crash appears
             * TypeError: Cannot read property '0' of undefined *)
            Eliom_content.Html5.Manip.appendChild container d
          with exn ->
            firelog (sprintf "PIZDA %s" (Printexc.to_string exn) );
            firelog "finished"
        );
        Lwt.return ()
    in ()
  }}
  in
  ans
