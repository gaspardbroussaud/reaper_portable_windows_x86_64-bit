-- @description Create ReaComp sidechain routing (always new renamed instance)
-- @version 1.09
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent



  
  local threshold = 0.25
  local ratio = 0.06
  local defsendvol = 1
  
  
  
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
    ---------------------------------------------------
  
  ---------------------------------------------------
  function VF_GetTrackUnderMouseCursor()
    local screen_x, screen_y = GetMousePosition()
    local retval, info = reaper.GetTrackFromPoint( screen_x, screen_y )
    return retval
  end     
  --------------------------------------------------------------------------------------
  function main(threshold, ratio, defsendvol)
  
    -- get source
      local src_tr = {}
      for tr_i = 1, CountSelectedTracks(0) do
        track = GetSelectedTrack(0,tr_i-1)
        src_tr[#src_tr+1] = GetTrackGUID( track )
      end 
      if #src_tr == 0 then return end
  
    -- get dest
      local dest_tr = VF_GetTrackUnderMouseCursor()
      if not dest_tr then return end

    MPL_CreateReaCompSidechainRouting_incresachan(dest_tr) 
    MPL_CreateReaCompSidechainRouting_addcomp(dest_tr)
    MPL_CreateReaCompSidechainRouting_addsend(src_tr, dest_tr)
    
  end
  ---------------------------------------------------------------------  
  function MPL_CreateReaCompSidechainRouting_incresachan(dest_tr)
    local ch_cnt = GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN' )
    SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', math.max(4, ch_cnt) )
  end
  ---------------------------------------------------------------------  
  function MPL_CreateReaCompSidechainRouting_addcomp(dest_tr)
    local sccomp_name = 'ReaComp SC'
    for fx = 1,  reaper.TrackFX_GetCount( dest_tr ) do
      local retval, buf = reaper.TrackFX_GetFXName( dest_tr, fx-1 )
      if retval then  
        if buf:match(sccomp_name ) then return end
      end
    end
    
    local reacompid = TrackFX_AddByName( dest_tr, 'ReaComp (Cockos)', false, -1 )
    TrackFX_SetOpen(dest_tr, reacompid, true)
    TrackFX_SetParam(dest_tr, reacompid, 0, threshold)
    TrackFX_SetParam(dest_tr, reacompid, 1, ratio)    
    TrackFX_SetParam(dest_tr, reacompid, 8, (1/1084)*2) 
    reaper.TrackFX_SetNamedConfigParm( dest_tr, reacompid, 'renamed_name', sccomp_name )
  end
  ---------------------------------------------------------------------  
  function MPL_CreateReaCompSidechainRouting_addsend(src_tr, dest_tr)
    local dest_trGUID = GetTrackGUID( dest_tr )
    -- add sends                  
      for i = 1, #src_tr do
        if src_tr[i] ~= dest_trGUID then
          local src_tr = VF_GetMediaTrackByGUID(0, src_tr[i] )
          
          local new_id
          -- check for existing id
          for sid = 1, GetTrackNumSends( src_tr, 0 ) do
            local dest_tr_pointer = GetTrackSendInfo_Value( src_tr, 0, sid-1, 'P_DESTTRACK' )
            local dest_tr_pointerGUID = GetTrackGUID(dest_tr_pointer)
            if dest_tr_pointerGUID == dest_trGUID then 
              if GetTrackSendInfo_Value( src_tr, 0, sid-1 , 'I_DSTCHAN') ==2 then return end
            end
          end
          
          if not new_id then new_id = CreateTrackSend( src_tr, dest_tr ) end
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', 3)
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 2) -- 3/4
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_MIDIFLAGS', 31) -- MIDI None
        end
      end
  end
    --------------------------------------------------------------------- 
  if VF_CheckReaperVrs(7,true) then 
    Undo_BeginBlock()
    main(threshold, ratio, defsendvol)
    Undo_EndBlock('Create ReaComp sidechain routing', -1)  
  end 