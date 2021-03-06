open Core.Std

let create_strm_from_file file_name =
  let ch = In_channel.create file_name in
  let _ = input_line ch in
  Stream.from (fun _ ->
      match In_channel.input_line ch with
      | None -> In_channel.close ch; None
      | x -> x)
    
let user_freq_table =
  let tb = Hashtbl.Poly.create() in
  Stream.iter (fun u ->
      let id::s::_ = String.split ~on:',' u in
      ignore (Hashtbl.add tb ~key:id ~data:(s,0,0,0,0,0,0,0)))
    (create_strm_from_file "../dataset/user_profile_table.csv");
  tb

let user_balance_table =
  let tb = ref [] in
  Stream.iter (fun u ->
      let id::date::tbalance::_::total_purchase::direct_purchase::_
          ::_::total_redeem::_::_::_::_::_::_::_::_::_ =
        String.split ~on:',' u in
      tb := (id,
             Int.of_string date,
             Int.of_string tbalance,
             Int.of_string total_purchase,
             Int.of_string direct_purchase,
             Int.of_string total_redeem) :: !tb)
  (create_strm_from_file "../dataset/user_balance_table.csv");
  !tb

let () =
  let ch = Out_channel.create "freq_count_by_gender.csv" in
  List.iter user_balance_table
    ~f:(fun (id,date,tbalance,total_purchase,direct_purchase,
             total_redeem) ->
         let s,d,pur_freq,red_freq,tot_freq,tot_pur,tot_red,bal =
           uw (Hashtbl.find user_freq_table id) in
         if direct_purchase > 0 then (
           Hashtbl.set user_freq_table ~key:id
             ~data:(s,d,pur_freq+1,red_freq,tot_freq+1,
                    tot_pur+direct_purchase,tot_red,bal));
         if total_redeem > 0 then (
           Hashtbl.set user_freq_table ~key:id
             ~data:(s,d,pur_freq,red_freq+1,tot_freq+1,
                    tot_pur,tot_red+total_redeem,bal));
         if date > d then (
           Hashtbl.set user_freq_table ~key:id
             ~data:(s,date,pur_freq,red_freq,tot_freq,
                   tot_pur,tot_red,tbalance))
       );
  Out_channel.output_string ch
    "user_id,gender,purchase_frequent,redeem_frequent,total_frequent,purchase_amount,redeem_amount,final_balance\n";
    Hashtbl.iter user_freq_table ~f:(fun ~key ~data ->
      let s,d,pur_freq,red_freq,tot_freq,tot_pur,tot_red,bal = data
      in
      let pur_freq = Float.of_int pur_freq /. 427.0 in
      let red_freq = Float.of_int red_freq /. 427.0 in
      let tot_freq = Float.of_int tot_freq /. 427.0 in
      Printf.fprintf ch "%s,%s,%f,%f,%f,%d,%d,%d\n" key s pur_freq
        red_freq tot_freq tot_pur tot_red bal
    )
