*&---------------------------------------------------------------------*
*& Report /BVCCSAP/C1_BW_PR_PCHIER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report /bvccsap/c1_bw_pr_pchier.

types: begin of ts_dep_tab,
         node     type /bi0/oitctprcschn,
         dep_node type /bi0/oitctprcschn,
       end of ts_dep_tab.

types: begin of ts_dep_tree,
         node         type /bi0/oitctprcschn,
         parrent_node type /bi0/oitctprcschn,
         child_node   type /bi0/oitctprcschn,
         level        type n length 2,
       end of ts_dep_tree.

types: begin of ts_top_node,
         node type /bi0/oitctprcschn,
       end of ts_top_node.

data: lv_node type /bi0/oitctprcschn.
data: lv_level type n length 2.

data: lt_dep_tree type standard table of ts_dep_tree.
data: ls_dep_tree type ts_dep_tree.
field-symbols <fs_dep_tree> type ts_dep_tree.

data: lt_dep_tab type standard table of ts_dep_tab.
field-symbols: <fs_dep_tab> type ts_dep_tab.
data: lt_top_nodes type hashed table of ts_top_node with unique key node.
data: ls_top_nodes type ts_top_node.
field-symbols: <fs_top_nodes> type ts_top_node.
data: ls_dep_tab type ts_dep_tab.

data: lt_hier type standard table of /bi0/htctprcschn.
field-symbols: <fs_hier> like line of lt_hier.
data: ls_hier like line of lt_hier.

data: lv_true type bool value abap_true.

data: lv_max_nodeid type rshienodid.

*# create dataset
append initial line to lt_dep_tab assigning <fs_dep_tab>.
<fs_dep_tab>-node = 'A'.
<fs_dep_tab>-dep_node = 'B'.
append initial line to lt_dep_tab assigning <fs_dep_tab>.
<fs_dep_tab>-node = 'A'.
<fs_dep_tab>-dep_node = 'C'.
append initial line to lt_dep_tab assigning <fs_dep_tab>.
<fs_dep_tab>-node = 'B'.
<fs_dep_tab>-dep_node = 'D'.

append initial line to lt_dep_tab assigning <fs_dep_tab>.
<fs_dep_tab>-node = '1'.
<fs_dep_tab>-dep_node = '1B'.

append initial line to lt_dep_tab assigning <fs_dep_tab>.
<fs_dep_tab>-node = '1B'.
<fs_dep_tab>-dep_node = 'B'.
*


* Find Top Nodes
loop at lt_dep_tab assigning <fs_dep_tab>.
  loop at lt_hier transporting no fields where nodename = <fs_dep_tab>-node.
  endloop.
  if sy-subrc = 0.
    continue.
  endif.
  loop at lt_dep_tab transporting no fields where dep_node = <fs_dep_tab>-node.
  endloop.
  if sy-subrc = 4.
    ls_hier-nodeid = sy-tabix.
    lv_max_nodeid = sy-tabix.
    ls_hier-iobjnm = '0TCTPRCSCHN'.
*    ls_hier-nodename = 'I91_050   ' && <fs_dep_tab>-node.
    ls_hier-nodename = <fs_dep_tab>-node.
    insert ls_hier into table lt_hier.
  endif.
endloop.


* Find child nodes
loop at lt_hier assigning <fs_hier>.
  lv_node = <fs_hier>-nodename.
  lv_level = 1.
  lv_true = abap_true.

  while lv_true = abap_true.
    if lv_level = 1.
      loop at lt_dep_tab assigning <fs_dep_tab> where node = lv_node.
        append initial line to lt_dep_tree assigning <fs_dep_tree>.
        <fs_dep_tree>-node = <fs_hier>-nodename.
        <fs_dep_tree>-parrent_node = <fs_dep_tab>-node.
        <fs_dep_tree>-child_node = <fs_dep_tab>-dep_node.
        <fs_dep_tree>-level = lv_level.
      endloop.
    else.
      loop at lt_dep_tree assigning <fs_dep_tree> where node = <fs_hier>-nodename and level = lv_level - 1.
        loop at lt_dep_tab assigning <fs_dep_tab> where node = <fs_dep_tree>-child_node.
          ls_dep_tree-node = <fs_hier>-nodename.
          ls_dep_tree-parrent_node = <fs_dep_tab>-node.
          ls_dep_tree-child_node = <fs_dep_tab>-dep_node.
          ls_dep_tree-level = lv_level.
          insert ls_dep_tree into lt_dep_tree.
        endloop.
        if sy-subrc = 4.
          lv_true = abap_false.
        endif.

      endloop.
    endif.
    lv_level = lv_level + 1.
  endwhile.

endloop.

loop at lt_hier assigning <fs_hier>.
  loop at lt_dep_tab assigning <fs_dep_tab> where node = <fs_hier>-nodename.
    lv_max_nodeid = lv_max_nodeid + 1.
    ls_hier-nodeid = lv_max_nodeid .
    ls_hier-nodename = <fs_dep_tab>-dep_node.
    ls_hier-parentid = <fs_hier>-nodeid.
    insert ls_hier into lt_hier.
  endloop.
endloop.

lt_hier = lt_hier.