
<?php

	$bdd = new PDO('mysql:host=database_host;dbname=database_name', 'database_user', 'password');
	
?>

<html>

	<head>

		<meta http-equiv="Content-type" content="text/html; charset=UTF-8" />
		<title>Call System</title>
		<link rel="stylesheet" type="text/css" href="index.css" />
	
	</head>

	<body id="haut">
	
		<center>

		<div class="corps">

			<br/>
			<center> <h1> Call System </h1> </center>
		
			<div style="margin-left:10px; margin-right:10px">
			
				<h2> Call points </h2>
				
				<table border="1">
				
					<tr> 
						<th style="width:200px"> Name </th> 
						<th style="width:100px"> Points </th> 
					</tr> 
				
					<?php
				
						$result = $bdd->query("SELECT steamid, name, points FROM callsystem_points ORDER BY `callsystem_points`.`points` DESC");
						if ($result)
						{
							foreach($result as $row)
							{
								$steamid = $row["steamid"];
								$name = $row["name"];
								$points = $row["points"];
								echo("<tr> <th> <a href=\"http://steamcommunity.com/profiles/$steamid\"/> $name </th>");
								echo("<th> $points </th> </tr>");
							}
						}
				
					?>
					
				</table>
				
				<h2> Recent calls </h2>
				
				<table border="1" width="100%">
				
				<tr> 
					<th> Date </th> 
					<th> Player </th>
					<th> Admin </th> 
					<th> Message </th>
					<th> Accepted </th>
					<th> Conclusion or refusal reason </th> 
				</tr>
				
				<?php
				
					$result = $bdd->query("SELECT * FROM callsystem_calls ORDER BY `callsystem_calls`.`date` DESC LIMIT 100;");
					if ($result)
					{
						foreach($result as $row)
						{
							$accepted = $row["accepted"];
							if ($accepted == 1)
								echo("<tr style=\"background-color:#9ECEA1\">");
							else
								echo("<tr style=\"background-color:#F75262\">");
							$date = gmdate("Y-m-d T H:i:s", $row["date"]);
							$ply = $row["calling_ply"];
							$ply_name = $bdd->query("SELECT name FROM callsystem_points WHERE steamid = $ply LIMIT 1;")->fetchColumn();
							$admin = $row["admin"];
							$admin_name = $bdd->query("SELECT name FROM callsystem_points WHERE steamid = $admin LIMIT 1;")->fetchColumn();
							$message = $row["message"];
							$admin_message = $row["accepted"] == 1 && $row["conclusion"] || $row["refuse_reason"];
							echo("<th>$date</th>");
							echo("<th> <a href=\"http://steamcommunity.com/profiles/$ply\"/> $ply_name </th>");
							echo("<th> <a href=\"http://steamcommunity.com/profiles/$admin\"/> $admin_name </th>");
							echo("<th> $message</th>");
							if ($accepted == 1)
							{
								echo("<th>Yes</th>");
								$admin_message = $row["conclusion"];
								echo("<th> $admin_message </th> </tr>");
							}
							else
							{
								echo("<th>No</th>");
								$admin_message = $row["refuse_reason"];
								echo("<th> $admin_message </th> </tr>");
							}
						}
					}
				
				?>

				</table>
			
			</div>
				
		</div>

		</center>
	
	</body>
</html>