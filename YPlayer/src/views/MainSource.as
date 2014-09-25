import models.SongVO;

private function initSongWhileTimeLoop():void
{
	var songs:Array=api.getCurrentTimeSongs();
	song1=songs[0];
	if (songs.length > 1)
		song2=songs[1];
}

private function getSongWhileTimeNotLoop():Boolean
{
	var has:Boolean;
	var now:Date=api.now;
	var temp:Number;
	nearestSong=null;
	firstSong=null;

	for (var i:int; i < api.songs.length; i++)
	{
		vo=api.songs[i] as SongVO;
		if (!nearestSong)
			nearestSong=vo;
		if (!firstSong)
			firstSong=vo;
		if (vo) //如果是歌曲
		{
			if (vo.playTime.date != now.date) //强制date一致方便进行time比对
				vo.playTime.date=now.date;
			//歌曲播放时间同当前时间差
			var result:Number=vo.playTime.getTime() + vo.duration * 1000 - now.getTime();
			var nn:Number=nearestSong.playTime.getTime() - now.getTime();
			var vn:Number=vo.playTime.getTime() - now.getTime();
			nearestSong=nn < vn ? nearestSong : vo;
			if (temp)
			{
				result-=temp;
				temp=0;
			}
			if (result > 1000 && result < vo.duration * 1000)
			{
				if (vo != song1)
				{
					vo=api.songs[i];
					playingIndex=i;
					has=true;
					if (i != api.songs.length - 1)
					{
						for (i++; i < api.songs.length - 1; i++)
						{
							song2=api.songs[i] as SongVO;
							if (song2)
								break;
						}
					}
					else
						song2=null
					song1=vo;
					break;
				}
				else
				{
					temp=result;
				}
			}
		}
	}

	return has;
}

private function switchSong():Boolean
{
	var has:Boolean=true;
	var i:int;

	if (song2)
	{
		song1=song2;
		var index:int=api.songs.indexOf(song2);
		if (api.isCurrentTimeLoop)
		{
			var songs:Array=api.getCurrentTimeSongs();
			index=songs.indexOf(song2);
			if (index == songs.length - 1)
				index=0;
			else
				index+=1;
			song2=songs[index];
		}
		else if (index != api.songs.length - 1)
		{
			for (index++; i < api.songs.length - 1; index++)
			{
				song2=api.songs[index] as SongVO;
				if (song2)
					break;
			}
		}
		else
		{
			song2=null;
		}
	}
	else if (api.isCurrentTimeLoop)
	{
		initSongWhileTimeLoop();
	}
	else
	{
		song1=null;
		has=false;
	}

	return has;
}
