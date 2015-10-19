#!/usr/local/bin/php
<?php 
/*
	$Id: firewall_ippools_edit.php 522 2015-04-02 15:47:41Z andywhite $
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

$pgtitle = array("Firewall", "IPpools", "Edit IPpool");
require("guiconfig.inc");

if (!is_array($config['ippools']['ippool']))
	$config['ippools']['ippool'] = array();

ippools_sort();

$a_ippools = &$config['ippools']['ippool'];
$a_ippoolmembers = &$config['ippools']['ippoolmember'];


$pid = $_GET['poolid'];
if (isset($_POST['poolid']))
	$pid = $_POST['poolid'];

$pooldetails = get_ippool_details($pid);

if (is_array($pooldetails)) {
	$pconfig['name'] = $pooldetails[0];
	$pconfig['descr'] = $pooldetails[1];
	$pconfig['poolid'] = $pid;
} 

if ($_POST) {

	unset($input_errors);
	$pconfig = $_POST;

	/* input validation */
	$reqdfields = explode(" ", "name");
	$reqdfieldsn = explode(",", "Name");
	
	do_input_validation($_POST, $reqdfields, $reqdfieldsn, &$input_errors);
	
	if (($_POST['name'] && !is_validippoolname($_POST['name']))) {
		$input_errors[] = "The ippool name may only consist of the characters a-z, A-Z, 0-9 and '-' (dash).";
	}
	
	/* check for name conflicts */
	foreach ($a_ippools as $ippool) {
		if (isset($pid) && ($pconfig['poolid'] = $pid))
			continue;

		if ($ippool['name'] == $_POST['name']) {
			$input_errors[] = "An ippool with this name already exists.";
			break;
		}
	}

	if (!$input_errors) {
		$ippool = array();
		$ippool['name'] = $_POST['name'];
		$ippool['descr'] = $_POST['descr'];

		if (isset($pid) && ($pconfig['poolid'] = $pid)) {
			$ippool['poolid'] = $_POST['poolid'];
			foreach ($a_ippools as $pkey => $ippools) {
				if ($ippools['poolid'] == $pid) {
					$a_ippools[$pkey] = $ippool; 
					break;
				}
			}
		}else{
			$ippool['poolid'] =  uniqid('p:');
			$a_ippools[] = $ippool;
		}
		touch($d_ippoolsdirty_path);
		
		write_config();
		
		header("Location: firewall_ippools.php");
		exit;
	}
}
?>
<?php include("fbegin.inc"); ?>
<table width="100%" border="0" cellpadding="0" cellspacing="0" summary="tab pane">
  <tr><td class="tabnavtbl">
  <ul id="tabnav">
  
  </ul>
  </td></tr>
  <tr> 
    <td class="tabcont">

<?php if ($input_errors) print_input_errors($input_errors); ?>
            <form action="firewall_ippools_edit.php" method="post" name="iform" id="iform">
              <table width="100%" border="0" cellpadding="6" cellspacing="0" summary="content pane">
                <tr> 
                  <td valign="top" class="vncellreq">Name</td>
                  <td class="vtable"><?=$mandfldhtml;?><input name="name" type="text" class="formfld" id="name" size="40" value="<?=htmlspecialchars($pconfig['name']);?>"> 
                    <br> <span class="vexpl">The name of the ippool may only consist 
                    of the characters a-z, A-Z, 0-9 and '-' (dash).</span></td>
                </tr>
                <tr> 
                  <td width="22%" valign="top" class="vncell">Description</td>
                  <td width="78%" class="vtable"> <input name="descr" type="text" class="formfld" id="descr" size="40" value="<?=htmlspecialchars($pconfig['descr']);?>"> 
                    <br> <span class="vexpl">You may enter a description here 
                    for your reference (not parsed).</span></td>
                </tr>
                <tr> 
                  <td width="22%" valign="top">&nbsp;</td>
                  <td width="78%"> <input name="Submit" type="submit" class="formbtn" value="Save"> 
                  <input name="poolid" type="hidden" value="<?=htmlspecialchars($pconfig['poolid']);?>"> 
                    <?php if (isset($id) && $a_ippools[$id]): ?>
                    <input name="id" type="hidden" value="<?=htmlspecialchars($id);?>"> 
                    <?php endif; ?>                    
                  </td>
                </tr>
              </table>
              
              <?php if (isset($pid)) { ?>
              <table width="100%" border="0" cellpadding="0" cellspacing="0" summary="mac=mapping widget">
			  		<tr> 
					  <td colspan="2" valign="top" class="optsect_t">
					  <table border="0" cellspacing="0" cellpadding="0" width="100%" summary="checkbox pane">
					  <tr><td class="optsect_s"><strong>IP Pool Members</strong></td></tr>
					  </table></td>
					</tr>
                <tr>
                  <td width="30%" class="listhdrr">IP address</td>
                  <td width="60%" class="listhdr">Description</td>
                  <td width="10%" class="list"></td>
				</tr>
			  <?php $i = 1; foreach ($a_ippoolmembers as $member): 
			  	if ($member['poolid'] != $pconfig['poolid'] ) continue;?>
                <tr>
                  <td class="listlr">
                    <?=htmlspecialchars($member['address']);?>&nbsp;
                  </td>
                  <td class="listbg">
                    <?=htmlspecialchars($member['descr']);?>&nbsp;
                  </td>
                  <td valign="middle" nowrap class="list"> <a href="firewall_ippools_member_edit.php?id=<?=$i;?>&amp;poolid=<?=htmlspecialchars($pconfig['poolid']);?>"><img src="e.png" title="edit member" width="17" height="17" border="0" alt="edit mapping"></a>
                     &nbsp;<input name="del_<?=$i;?>" type="image" src="x.png" width="17" height="17" title="delete member" alt="delete member" onclick="return confirm('Do you really want to delete this pool member ?')"></td>
				</tr>
			  <?php $i++; endforeach; ?>
                <tr> 
                  <td class="list" colspan="2"></td>
                  <td class="list"> <a href="firewall_ippools_member_edit.php?poolid=<?=htmlspecialchars($pconfig['poolid']);?>"><img src="plus.png" title="add member" width="17" height="17" border="0" alt="add mapping"></a></td>
				</tr>
              </table>
              <?php } ?>
			</td>
			</form>
	</tr>
</table>
<?php include("fend.inc"); ?>
