<?php
/*
Plugin Name:	Varnish WordPress
Description:	This plugin provides the ability to intergrate varnish with wordpress.
Version:		1.5
Author:			AdminGeekZ
Author URI:		http://www.admingeekz.com
License: 	Copyright 2013  AdminGeekZ Ltd (pr@admingeekz.com)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License, version 2, as 
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

class VarnishWordPress {

	public $settings=array(
				'varnishwp_version' => 1.5,
				'varnishwp_enabled' => 0,
                                'varnishwp_backends' => '127.0.0.1:6081',
                                'varnishwp_timeout' => 30,
                                'varnishwp_disablefeeds' => 0,
                                'varnishwp_purgeall' => 0,
                                'varnishwp_logging' => 0,
                                'varnishwp_logname' => '/tmp/varnish-wordpress.log',
			);

	public $varnishwp_clear=array();
	private $varnishwp_host;
	private $varnishwp_prefix;

	function __construct() {
		//Likely executing over CLI
		if (!function_exists('register_activation_hook'))
			exit();

		register_activation_hook(__FILE__, array($this, 'varnishwp_activate'));
		register_deactivation_hook(__FILE__, array($this, 'varnishwp_deactivate'));
		register_uninstall_hook(__FILE__,  array($this, 'varnishwp_uninstall'));


               foreach($this->settings as $settingname=>$setting) {
                        if(get_option($settingname))
				$this->settings["$settingname"] = get_option($settingname);
                }

		$postactions=array(
				'edit_post',
				'deleted_post',
				'trashed_post',
				'publish_to_future',
				'xmlrpc_publish_post'
				);

		$commentactions=array(
				'edit_comment',
				'deleted_comment',
				'comment_post',
				'trashed_comment',
				'untrashed_comment'
				);



		foreach ($postactions as $action) {
			add_action($action, array($this, 'varnishwp_purgepost'), 99);
			add_action($action, array($this, 'varnishwp_purgecommon'), 99);
		}

		foreach ($commentactions as $action) {
			add_action($action, array($this, 'varnishwp_purgecomments'), 99);
		}

		add_action('switch_theme', array($this, 'varnishwp_purgetheme'), 99);
		add_action('transition_post_status', array($this, 'varnishwp_purgepoststatus'), 99, 3);

		//Do all purge actions at end for performance reasons
                add_action('shutdown', array($this, 'varnishwp_shutdown'), 99);

		//Bit hacky,  see if there is a better way
		$this->varnishwp_setprefix();

		if (is_admin()) 
			add_action('admin_menu', array($this, 'varnish_admin_menu'));

	}

	function varnishwp_activate() {
		if (!current_user_can('activate_plugins')) 
			return;

		foreach($this->settings as $settingname=>$setting) {
			if(get_option($settingname))
				continue;

			add_option($settingname, $setting, '', 'yes');
		}
	}

	function varnishwp_uninstall() {

		if (!defined('WP_UNINSTALL_PLUGIN')) 
   			exit();

		foreach($this->settings as $settingname=>$setting) {
			if (get_option($settingname)) 
				delete_option($settingname);
		}
	}

	function varnishwp_shutdown() {
		//If there is items to purge
		if (!empty($this->varnishwp_clear)) {
			$this->varnishwp_dopurge($this->varnishwp_clear);
		}
	}


	function varnishwp_setprefix() {
		$url = get_bloginfo('url');
		preg_match("/http:\/\/(.*?)(\/|$)/", $url, $matches);
		$this->varnishwp_host=$matches[1];
		$matches="";
		//strip trailing slash
		if(substr($url, -1) == '/') {
			$url = substr($url, 0, -1);
		}
		if (preg_match("/http:\/\/.*(\/.*?)(\/|$)/", $url, $matches)) {
			$this->varnishwp_prefix=$matches[1];
		}
	}

	function varnishwp_log($log) {
		if ($this->settings["varnishwp_logging"])
			@file_put_contents($this->settings["varnishwp_logname"], date("D M j G:i:s T Y")." - ${log}\n", FILE_APPEND);
	}

	function varnishwp_dopurge($urls) {
                $host=$this->varnishwp_host;
		//Remove duplicates
		$urls=array_unique($urls);
 		foreach ($urls as $url) {
			$url=$this->varnishwp_prefix.$url;
			foreach(preg_split("/((\r?\n)|(\r\n?))/",$this->settings["varnishwp_backends"]) as $backend) {
				$backend=explode(":", $backend);
				$this->varnishwp_log("Processing ${backend[0]}:${backend[1]} ");
				$fp = @fsockopen($backend[0], $backend[1], $errno,  $errstr, $this->settings["varnishwp_timeout"]);
				if (!$fp) {
					$this->varnishwp_log("Error connecting to ${backend[0]}:${backend[1]} : ${errstr} (${errno})");
				}
				else {
					$out = "BAN ${url}\r\n";
					$out .= "Host: ${host}\r\n";
					$out .= "Connection: Close \r\n\r\n";
					@fwrite($fp, $out);
					$result = @fread($fp, 22);
					@fclose($fp);
					if (preg_match('/ 200 /', $result)) {
					$this->varnishwp_log("Successfully purged ${url}");
					}
					else {
					if (!preg_match("/HTTP/", $result)) {
						$result="Unable to detect varish authorization,  are you sure you are connecting to a varnish backend?";
					}
					$this->varnishwp_log("Error purging ${url} (${result})");
					}
				}
			}
		}
	}

	function varnishwp_deactivate() {

		if (!current_user_can('activate_plugins'))
			return;

		if (get_option('varnishwp_enabled'))
			update_option('varnishwp_enabled', '0');

	}

	function varnishwp_checkpurge($urls) {
		if ($this->settings["varnishwp_purgeall"] == "1") {
			return "";
		}
		return $urls;
	}

        function varnishwp_purgetheme() {
                $this->varnishwp_purge("");
        }

	function varnishwp_purgepost($id) {
		$url = str_replace(get_bloginfo('url'),"",get_permalink($id));
		$url = $this->varnishwp_checkpurge($url);
		$this->varnishwp_purge($url);
	}

	function varnishwp_purgepoststatus($old, $new, $id) {
		$this->varnishwp_purgepost($id);
	}

	function varnishwp_purgecommon() {
                $url = $this->varnishwp_checkpurge("/$");
		if ($url != "") {
		$this->varnishwp_purge("/$");
		$this->varnishwp_purge("/category/(.*)");
		if ($this->settings["varnishwp_disablefeeds"] != "1") {
		//RSS
		$feed=str_replace(get_bloginfo('url'),"",get_bloginfo('rss_url'));
		$this->varnishwp_purge($feed);
		//Strip /RSS to get just /feed
                $feed=substr($feed,0, -4);
                $this->varnishwp_purge($feed);
		//Atom
                $feed=str_replace(get_bloginfo('url'),"",get_bloginfo('atom_url'));
                $this->varnishwp_purge($feed);
                //Comments
                $feed=str_replace(get_bloginfo('url'),"",get_bloginfo('comments_rss2_url'));
                $this->varnishwp_purge($feed);
		}
		return;
		}
		return;
	}

	function varnishwp_purgecomments($id) {
		$comment=get_comment($id);
		$url="?comments_popup=".$id;
                $url = $this->varnishwp_checkpurge($url);
		if ($url != "") {
		$this->varnishwp_purge($url);
		}
	}


	function varnishwp_purge($url) {
		array_push($this->varnishwp_clear, $url);
	}

	function varnish_admin_menu() {
		add_options_page('Varnish WordPress', 'Varnish', 8, 'Varnish-WordPress', array($this, 'varnish_admin_interface'));
	}


	function varnish_admin_interface() {
		$timeouterror="";
		$logerror="";
		$success="";
		$backenderror="";
	        if ($_SERVER["REQUEST_METHOD"] == "POST" && !empty($_POST['varnishwp_enabled'])) {
                $varnishwp_enabled=($_POST['varnishwp_enabled'] == "1" ? 1 : 0);
                $varnishwp_logging=($_POST['varnishwp_logging'] == "1" ? 1 : 0);
                $varnishwp_disablefeeds=($_POST['varnishwp_disablefeeds'] == "1" ? 1 : 0);
                $varnishwp_purgeall=($_POST['varnishwp_purgeall'] == "1" ? 1 : 0);
                $varnishwp_timeout=$_POST['varnishwp_timeout'];
                $varnishwp_logname=$_POST['varnishwp_logname'];
		$varnishwp_version=$this->settings['varnishwp_version'];
                if (!is_numeric($varnishwp_timeout)) {
                        $timeouterror="<br /><font color=\"red\"><strong>Timeout must be a valid number</strong></font>";
                        $varnishwp_timeout=$this->settings["varnishwp_timeout"];
		}

                if (($varnishwp_logging && !is_writable($varnishwp_logname))) { 
                        $logerror="<br /><font color=\"red\"><strong>Unable to write to specified log file name.  Make sure it exists and the webbackend can write to it.</strong></font>";
                        $varnishwp_logname=$this->settings["varnishwp_logname"];
                }


		$varnishwp_backends=$_POST['varnishwp_backends'];
		foreach(preg_split("/((\r?\n)|(\r\n?))/",$varnishwp_backends) as $backend) {
			//Check it's a valid IP:PORT or DOMAIN:PORT combo
			if(!preg_match("/(^[\d\w.-_]+:[0-9]{1,5}$)/",$backend)) {
				$backenderror="<br /><font color=\"red\">You must enter a valid varnish host to purge in the correct format</font>";
			}
		}

		if(!empty($backenderror))
			$varnishwp_backends=$this->settings["varnishwp_backends"];
		foreach ($this->settings as $settingname=>$setting) {
			update_option($settingname, ${$settingname});
			$this->settings["$settingname"] = ${$settingname};

		}
		if (empty($timeouterror) && empty($logerror) && empty($backenderror)) {
			$success="<font color=\"green\"><strong>Changes saved successfully.</strong></font>";
		}
        }
	elseif ($_SERVER["REQUEST_METHOD"] == "POST" && !empty($_POST['varnishwp_manualpurge'])) {
		$urls=array();
		foreach (preg_split("/((\r?\n)|(\r\n?))/",$_POST['varnishwp_manualpurge']) as $url) {
			$url=str_replace(get_bloginfo('url'),"",$url);
			array_push($urls, $url);
		}
		$this->varnishwp_dopurge($urls);
		$purgesuccess="<font color=\"green\"><strong>Purge requests sent.</strong></font>";
	}

//Redeclare values for the EOF
$varnishwp_enabled=$this->settings["varnishwp_enabled"];
$varnishwp_backends=$this->settings["varnishwp_backends"];
$varnishwp_timeout=$this->settings["varnishwp_timeout"];
$varnishwp_logname=$this->settings["varnishwp_logname"];
$varnishwp_logging=$this->settings["varnishwp_logging"];
$varnishwp_disablefeeds=$this->settings["varnishwp_disablefeeds"];
$varnishwp_purgeall=$this->settings["varnishwp_purgeall"];
$enabledvalue = ($varnishwp_enabled == 1 ? 'checked' : '');
$loggingvalue = ($varnishwp_logging == 1 ? 'checked' : '');
$disablefeedsvalue = ($varnishwp_disablefeeds == 1 ? 'checked' : '');
$purgeallvalue = ($varnishwp_purgeall == 1 ? 'checked' : '');
$location=$_SERVER['REQUEST_URI'];
$varnishwp_defaultpurge="^/$
^/feed$
/category/(.*)";


$defaultpurgevalue = (!empty($_POST['varnishwp_manualpurge']) ? htmlentities($_POST['varnishwp_manualpurge']) : $varnishwp_defaultpurge);
echo <<<EOF
<div class="wrap">
<div id="icon-options-general" class="icon32"><br /></div><h2>Varnish Wordpress Plugin</h2>

<p>This plugin will purge the varnish cache on
<li>Post changes (new, edit, trash, delete).</li>
<li>Page changes (add, edit, remove)</li>
<li>Comment changes (add, edit, approve,  unapprove,  spam,  trash,  delete)</li>
<li>Theme changes</li>
</p>
<p>
<h2><strong>Manual Purge</strong></h2>
$purgesuccess
<form name="varnishwppurge" action="$location" method="POST">
<table class="form-table">
        <tr>
                <th><label for="backends">Manual Purge</label>
                    <p><em>Input the urls you would like to manually purge. One on each line.  Leave blank to purge the entire cache. <br />Full http:// urls are also supported<br /><strong>Example: /^$ will purge the index</strong></em>$purgeerror</p>
                </th>
                <td><textarea name="varnishwp_manualpurge" id="varnishwp_manualpurge" cols="40" rows="5" class="regular-text code" />$defaultpurgevalue</textarea></td>
        </tr>
        <tr>
                <th><label for="save">Purge URLs</label></th>
                <td><input name="submit" id="submit" type="submit" value="Purge!" class="regular-text code" /></td>
        </tr>

        </table>
</form>
</p>
<p>
<h2><strong>Plugin Configuration</strong></h2>
$success</p>
<form name="vanishwpsettings" action="$location" method="POST">
<table class="form-table">
        <tr>
                <th><label for="backends">Varnish Servers</label>
                    <p><em>Specify the varnish backends you'd like to purge.  Add each new backend on a new line. <br /><strong>Format: ip:port</strong></em>$backenderror</p>
                </th>
                <td><textarea name="varnishwp_backends" id="varnishwp_backends" cols="40" rows="5" class="regular-text code" />$varnishwp_backends</textarea></td>
        </tr>
        <tr>
                <th><label for="timeout">Timeout</label>
                    <p><em>This is the maximum amount of time we will try connect to each varnish backend.</em>$timeouterror</p>
                </th>
                <td><input type="text" name="varnishwp_timeout" id="varnishwp_timeout" value="$varnishwp_timeout" class="regular-text code" /></td>
        </tr>
        <tr>
                <th><label for="timeout">Debug Log Path</label>
                    <p><em>This is the path of the debug log file,  this must be writeable by the webbackend.</em>$logerror</p>
                </th>
                <td><input type="text" name="varnishwp_logname" id="varnishwp_logname" value="$varnishwp_logname" class="regular-text code" /></td>
        </tr>
        <tr>
                <th><label for="enabled">Enabled</label></th>
                <td><input name="varnishwp_enabled" id="varnishwp_enabled" type="checkbox" value="1" $enabledvalue /></td>
        </tr>
        <tr>
                <th><label for="timeout">Debug Logging</label>
                    <p><em>This will log all the PURGE requests we make to varnish.  Default off.</em></p>
                </th>
                <td><input name="varnishwp_logging" id="varnishwp_logging" type="checkbox" value="1" $loggingvalue /></td>
        </tr>
        <tr>
                <th><label for="disablefeeds">Disable Feed Purging</label>
                    <p><em>This will disable purging for the RSS, Atom and Comment feeds. Default off</em></p>
                </th>
                <td><input name="varnishwp_disablefeeds" id="varnishwp_disablefeeds" type="checkbox" value="1" $disablefeedsvalue /></td>
        </tr>

        <tr>
                <th><label for="purgeall">Purge All on changes</label>
                    <p><em>This will purge your entire cache instead of individual URL's when changes are detected. This is <strong>not</strong> recommended and could have performance impacts for large installations.</em></p>
                </th>
                <td><input name="varnishwp_purgeall" id="varnishwp_purgeall" type="checkbox" value="1" $purgeallvalue /></td>
        </tr>
        <tr>
                <th><label for="save">Save Configuration</label></th>
                <td><input name="submit" id="submit" type="submit" value="Save!" class="regular-text code" /></td>
        </tr>

        </table>
</form>
</div>
EOF;
}

}
$varnishwordpress = new VarnishWordPress();
?>
