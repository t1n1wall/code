#!/usr/local/bin/php
<?php
/*
	$Id: firewall_ippools.php 522 2015-04-02 15:47:41Z andywhite $
	part of t1n1wall (http://t1n1wall.com)

	Copyright (C) 2015 Andrew White <andywhite@t1n1wall.com>.
	All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
	
	1. Redistributions of source code must retain the above copyright notice,
	   this list of conditions and the following disclaimer.
	
	2. Redistributions in binary form must reproduce the above copyright
	   notice, this list of conditions and the following disclaimer in the
	   documentation and/or other materials provided with the distribution.
	
	THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
	AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
	AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
	OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
*/

$pgtitle = array("Firewall", "IP Pools");
require("guiconfig.inc");

if (!is_array($config['ippools']['ippool']))
	$config['ippools']['ippool'] = array();

ippools_sort();
$a_ippools = &$config['ippools']['ippool'];

if ($_POST) {
	if ($_POST['apply']) {
		$retval = 0;
		if (!file_exists($d_sysrebootreqd_path)) {
			config_lock();
			/* reload all components that use ippool */
			$retval = filter_configure();
			config_unlock();
		}
		$savemsg = get_std_save_message($retval);
		if ($retval == 0) {
			if (file_exists($d_ippoolsdirty_path))
				unlink($d_ippoolsdirty_path);
		}
	}
}
	
if (isset($_POST['del_x']) && is_array($_POST['entries'])) {
	/* delete all members of the pool and the pool */
	$a_ippoolmembers = &$config['ippools']['ippoolmember'];

	foreach ($_POST['entries'] as $entry) {
		foreach ($a_ippools as $pkey => $ippool) {
			if ($ippool['poolid'] == $entry){
				foreach ($a_ippoolmembers as $mkey => $member) {
					if ($member['poolid'] != $entry) continue;
					/* delete member of pool */
					unset($a_ippoolmembers[$mkey]);
				}
				/* delete pool */
				unset($a_ippools[$pkey]);
			}
		}
		/* you could loop through firewall rules here and disable relevant rules
		   however, logic elsewhere, like aliases , is to skip rules that become 
		   invalid by deleting dependancies like alias definitions.
		   Also, a user could re-enable the rule or hack their config.xml, so you need the skip logic anyway */
	}


	write_config();
	touch($d_ippoolsdirty_path);
	header("Location: firewall_ippools.php");
	exit;
}
?>
<?php include("fbegin.inc"); ?>
<form action="firewall_ippools.php" method="post">
<?php if ($savemsg) print_info_box($savemsg); ?>
<?php if (file_exists($d_ippoolsdirty_path)): ?><p>
<?php print_info_box_np("The ippool list has been changed.<br>You must apply the changes in order for them to take effect.");?><br>
<input name="apply" type="submit" class="formbtn" id="apply" value="Apply changes"></p>
<?php endif; ?>
<table width="100%" border="0" cellpadding="0" cellspacing="0" summary="tab pane">
  <tr><td class="tabnavtbl">
	<ul id="tabnav">
<?php
        $tabs = array('Aliases' => 'firewall_aliases.php',
                          'IP Pools' => 'firewall_ippools.php');
        dynamic_tab_menu($tabs);
?>
	</ul>
	</td></tr>
	<tr>
		<td class="tabcont">
              <table width="100%" border="0" cellpadding="0" cellspacing="0" summary="content pane">
                <tr>
    			  <td width="5%" class="list">&nbsp;</td>
                  <td width="30%" class="listhdrr">Name</td>
                  <td width="55%" class="listhdr">Description</td>
                  <td width="10%" class="list"></td>
				</tr>
			  <?php $i = 0; foreach ($a_ippools as $ippool): ?>
                <tr>
				  <td class="listt"><input type="checkbox" name="entries[]" value="<?=htmlspecialchars($ippool['poolid']);?>" style="margin: 0 5px 0 0; padding: 0; width: 15px; height: 15px;"></td>
                  <td class="listlr">
                    <?=htmlspecialchars($ippool['name']);?>
                  </td>
                  <td class="listbg">
                    <?=htmlspecialchars($ippool['descr']);?>&nbsp;
                  </td>
                  <td valign="middle" nowrap class="list"> <a href="firewall_ippools_edit.php?poolid=<?=htmlspecialchars($ippool['poolid']);?>"><img src="e.png" title="edit ippool" width="17" height="17" border="0" alt="edit ippool"></a></td>
				</tr>
			  <?php $i++; endforeach; ?>
                <tr> 
                  <td class="list" colspan="3"></td>
                  <td class="list">
					<input name="del" type="image" src="x.png" width="17" height="17" title="delete selected ippools" alt="delete selected ippools" onclick="return confirm('Do you really want to delete the selected IP Pool? All members will be delete and filter rules that use this pool will be disabled.')">
					<a href="firewall_ippools_edit.php"><img src="plus.png" title="add ippool" width="17" height="17" border="0" alt="add ippool"></a></td>
				</tr>
              </table>
            </form>
        </td>
    </tr>
</table>
<p><span class="vexpl"><span class="red"><strong>Note:<br>
                </strong></span>If a pool cannot be resolved (e.g. because you
                 deleted it) or has no members, the corresponding filter 
                 will be considered invalid and skipped.</span></p>
<?php include("fend.inc"); ?>
