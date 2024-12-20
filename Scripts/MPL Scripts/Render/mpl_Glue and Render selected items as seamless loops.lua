-- @description Glue and Render selected items as seamless loops
-- @version 1.01
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end

     
  --NOT gfx NOT reaper
  -----------------------------------------------------------
  function main(it0)
    items_t = {}
    -- save items mute/selection ------------------
      for itemidx = 1, CountMediaItems( 0 ) do 
        local it = GetMediaItem( 0, itemidx-1 )
        items_t[itemidx] = {itptr = it,
                            mute = GetMediaItemInfo_Value(  it, 'B_MUTE'),
                            sel =  GetMediaItemInfo_Value(  it, 'B_UISEL')}
      end 
    -- prepare items ------------------
      for itemidx = 1, #items_t do 
        if it0 ~= items_t[itemidx].itptr then 
          SetMediaItemInfo_Value(  GetMediaItem( 0, itemidx-1 ), 'B_MUTE', 1 ) -- mute all except first 
          SetMediaItemInfo_Value(  GetMediaItem( 0, itemidx-1 ), 'B_UISEL', 0 ) -- unselect all except first 
         else
          SetMediaItemInfo_Value(  GetMediaItem( 0, itemidx-1 ), 'B_MUTE', 0 ) 
          SetMediaItemInfo_Value(  GetMediaItem( 0, itemidx-1 ), 'B_UISEL', 1 )   -- made first only selected        
        end
      end 
    -- mute all except selected, select only first ------------------
      for itemidx = 1, CountMediaItems( 0 ) do  
        SetMediaItemInfo_Value(  GetMediaItem( 0, itemidx-1 ), 'B_MUTE', 1 ) 
        SetMediaItemInfo_Value(  GetMediaItem( 0, itemidx-1 ), 'B_UISEL', 0 ) 
      end
      SetMediaItemInfo_Value(  it0, 'B_MUTE', 0 )
      SetMediaItemInfo_Value(  it0, 'B_UISEL', 1 )  
    -- save time selection ------------------
      local tsstart, tsend = GetSet_LoopTimeRange2( 0, false, false, 0, 0, false ) 
    -- twice time selection from item pos -> length
      local itpos = GetMediaItemInfo_Value(  it0, 'D_POSITION')  
      local itlen = GetMediaItemInfo_Value(  it0, 'D_LENGTH') 
      GetSet_LoopTimeRange2( 0, true, false, itpos, itpos+itlen*2, false ) 
    -- render
      SetMediaItemInfo_Value(  it0, 'B_LOOPSRC', 0) 
      Action(41588)-- Item: Glue items  
      it0 =   GetSelectedMediaItem( 0, 0 )
      SetMediaItemInfo_Value(  it0, 'D_LENGTH',itlen*2)
      Action(40209) -- Item: Apply track/take FX to items 
    -- cut by half
      rightitem = SplitMediaItem( it0, itpos + itlen )  
      SetMediaItemInfo_Value(  it0, 'D_LENGTH',itlen)  
    -- move tail to the end of item      
      SetMediaItemInfo_Value(  rightitem, 'D_POSITION',itpos)   
    -- select tail and original       
      SetMediaItemInfo_Value(  it0, 'B_UISEL', 1 ) 
    -- glue
      GetSet_LoopTimeRange2( 0, true, false, itpos, itpos+itlen, false ) 
      Action(41588)-- Item: Glue items
    -- restore time selection ------------------
      GetSet_LoopTimeRange2( 0, true, false, tsstart, tsend, false ) 
    -- restore items mute/selection ------------------
      for itemidx = 1, #items_t do 
        if items_t[itemidx].itptr and  ValidatePtr2( 0, items_t[itemidx].itptr, 'MediaItem*' ) then
          SetMediaItemInfo_Value(  items_t[itemidx].itptr, 'B_MUTE', items_t[itemidx].mute ) 
          SetMediaItemInfo_Value(  items_t[itemidx].itptr, 'B_UISEL', items_t[itemidx].sel ) 
        end
      end
    UpdateArrange()
  end
  
  ------------------------------------------------------------------------------------------------------
  function Action(s, sectionID, ME )  
    if sectionID == 32060 and ME then 
      MIDIEditor_OnCommand( ME, NamedCommandLookup(s) )
     else
      Main_OnCommand(NamedCommandLookup(s), sectionID or 0) 
    end
  end  
---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true)     then 
    local ret_ans = MB('Do you want to BATCH render selected items?', 'mpl_Glue and Render seamless loop',3 )
    if ret_ans == 6 then 
      reaper.PreventUIRefresh( -1 )
      reaper.Undo_BeginBlock2( 0 )
      for i = 1,  CountSelectedMediaItems( 0 ) do
        local it = GetSelectedMediaItem( 0, i-1 )
        main(it) 
      end
      reaper.Undo_EndBlock2( 0, 'Glue and Render seamless loop', 0 )
      reaper.PreventUIRefresh( 1 )
    end 
  end