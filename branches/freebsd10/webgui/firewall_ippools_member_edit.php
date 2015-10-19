#!/usr/local/bin/php
<?php 
/*
	$Id: firewall_ippools_member_edit.php 522 2015-04-02 15:47:41Z andywhite $
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

$pgtitle = array("Firewall", "IPpools", "Edit IPpool Member");
require("guiconfig.inc");

if (!is_array($config['ippools']['ippoolmember']))
	$config['ippools']['ippoolmember'] = array();

if (ipv6enabled()) {
	$maxsubnetbits=128;
} else {
	$maxsubnetbits=32;
}
$a_ippoolmembers = &$config['ippools']['ippoolmember'];

$id = $_GET['id'];
if (isset($_POST['id']))
	$id = $_POST['id'];

$poolid = $_GET['poolid'];
if (isset($_POST['poolid']))
	$poolid = $_POST['poolid'];

$pooldetails = get_ippool_details($poolid);

if (is_array($pooldetails)) {
	$pconfig['name'] = $pooldetails[0];
} 

$i = 1; 

foreach ($a_ippoolmembers as $mkey => $member) {
	if ($member['poolid'] != $poolid ) continue;
		if (isset($id) && $i==$id) {
			$pconfig['poolid'] = $poolid;
			$pconfig['descr'] = $member['descr'];
			list($pconfig['address'],$pconfig['address_subnet']) = explode('/', $member['address']);
			if ($pconfig['address_subnet']) {
				$pconfig['type'] = "network";
			}
			else{
				$pconfig['type'] = "host";
			}
			break;
		}
	$i++;
}



if ($_POST) {

	unset($input_errors);
	$pconfig = $_POST;

	/* input validation */
	$reqdfields = explode(" ", "poolid address");
	$reqdfieldsn = explode(",", "poolid,Address");
	
	if ($_POST['type'] == "network") {
		$reqdfields[] = "address_subnet";
		$reqdfieldsn[] = "Subnet bit count";
	}
	
	do_input_validation($_POST, $reqdfields, $reqdfieldsn, &$input_errors);

	if (($_POST['address'] && !is_ipaddr4or6($_POST['address']))) {
		$input_errors[] = "A valid address must be specified.";
	}
	if (($_POST['address_subnet'] && !is_numeric($_POST['address_subnet']))) {
		$input_errors[] = "A valid subnet bit count must be specified.";
	}
	if ( ($_POST['address_subnet']) && (!is_numeric($_POST['address_subnet']) || !is_networkaddr4or6($_POST['address'] . "/" . $_POST['address_subnet'])) ) {
		$input_errors[] = "A valid network subnet address must be specified.";
	}
	
	if (!$input_errors) {
		$member = array();
		$member['poolid'] = $_POST['poolid'];
		if ($_POST['type'] == "network")
			$member['address'] = $_POST['address'] . "/" . $_POST['address_subnet'];
		else
			$member['address'] = $_POST['address'];
		$member['descr'] = $_POST['descr'];

		if (isset($id) && $a_ippoolmembers[$mkey])
			$a_ippoolmembers[$mkey] = $member;
		else
			$a_ippoolmembers[] = $member;
		
		touch($d_ippoolmdirty_path);
		
		write_config();
	
		header("Location: firewall_ippools_edit.php?poolid=" . $poolid);
		exit;
	}
}
?>
<?php include("fbegin.inc"); ?>
<script type="text/javascript">
<!--
function typesel_change() {
	switch (document.iform.type.selectedIndex) {
		case 0:	/* host */
			document.iform.address_subnet.disabled = 1;
			document.iform.address_subnet.value = "";
			break;
		case 1:	/* network */
			document.iform.address_subnet.disabled = 0;
			break;
	}
}
//-->
</script>

<?php if ($input_errors) print_input_errors($input_errors); ?>
            <form action="firewall_ippools_member_edit.php" method="post" name="iform" id="iform">
              <table width="100%" border="0" cellpadding="6" cellspacing="0" summary="content pane">
                <tr> 
                  <td valign="top" class="vncellreq">Pool Name</td>
                  <td class="vtable"><?=$pconfig['name'];?><input name="name" type="hidden" class="formfld" id="name" size="30" value="<?=$pconfig['name'];?>" >
                  </td>
                </tr>
                <tr> 
                  <td valign="top" class="vncellreq">Type</td>
                  <td class="vtable"> 
                    <select name="type" class="formfld" id="type" onChange="typesel_change()">
                      <option value="host" <?php if ($pconfig['type'] == "host") echo "selected"; ?>>Host</option>
                      <option value="network" <?php if ($pconfig['type'] == "network") echo "selected"; ?>>Network</option>
                    </select>
                  </td>
                </tr>
                <tr> 
                  <td width="22%" valign="top" class="vncellreq">Address</td>
                  <td width="78%" class="vtable"><?=$mandfldhtml;?><input name="address" type="text" class="formfld" id="address" size="20" value="<?=htmlspecialchars($pconfig['address']);?>">
                    / 
                    <select name="address_subnet" class="formfld" id="address_subnet">
                      <?php for ($i = $maxsubnetbits; $i >= 1; $i--): ?>
                      <option value="<?=$i;?>" <?php if ($i == $pconfig['address_subnet']) echo "selected"; ?>> 
                      <?=$i;?>
                      </option>
                      <?php endfor; ?>
                    </select> <br> <span class="vexpl">The address that this member 
                    represents.</span></td>
                </tr>
                <tr> 
                  <td width="22%" valign="top" class="vncell">Description</td>
                  <td width="78%" class="vtable"> <input name="descr" type="text" class="formfld" id="descr" size="40" value="<?=htmlspecialchars($pconfig['descr']);?>"> 
                    <br> <span class="vexpl">You may enter a description here 
                    for your reference (not parsed).</span></td>
                </tr>
                <tr> 
                  <td width="22%" valign="top">&nbsp;</td>
                  <input name="poolid" type="hidden" value="<?=htmlspecialchars($poolid);?>"> 
                  <td width="78%"> <input name="Submit" type="submit" class="formbtn" value="Save"> 
                    <?php if (isset($id) && $a_ippoolmembers[$id]): ?>
                    <input name="id" type="hidden" value="<?=htmlspecialchars($id);?>"> 
                    <?php endif; ?>
                  </td>
                </tr>
              </table>
</form>
<script type="text/javascript">
<!--
typesel_change();
//-->
</script>
<?php include("fend.inc"); ?>
