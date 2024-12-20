-- @description Toggle bypass all FX except instruments on all tracks
-- @version 1.52
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694 
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
  ---------------------------------------------------
  local scr_title = "Toggle Bypass all FX except instruments on all tracks"
  ---------------------------------------------------------
  function SetStrState()
    local str = ''
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      str = str..'bypass_states '..GetTrackGUID(tr)
      for fx = 1,  TrackFX_GetCount( tr ) do
        local state = TrackFX_GetEnabled( tr, fx-1 )
        if state == false then 
          str = str..' '..(fx-1)
        end
      end
      str = str ..'\n'
    end
    SetProjExtState( 0, 'MPL_BYPASSFX', 'state', str )
  end
  --------------------------------------------------------
  function GetStrState()
    local t = {}
    local retval, str = GetProjExtState( 0, 'MPL_BYPASSFX', 'state' )
    if retval ~= 1 or str == '' then return end
    for line in str:gmatch('[^\r\n]+') do 
      if line:match('bypass_states') then 
        local GUID = line:match('%{.-%}')
        if GUID then 
          t[GUID]= {}
          for dig in line:gmatch('%s[%d]+') do if tonumber(dig) then  t[GUID][tonumber(dig)+1] = 1 end end
        end
      end 
    end
    return t
  end
  --------------------------------------------------------- 
  function IsInstrument(track, fx)  
    local fx_instr = TrackFX_GetInstrument( track )
    return  fx_instr >= fx
  end
  ---------------------------------------------------------  
  function SetFXState(FX_state, t)
    for i = 1, CountTracks(0) do
      local tr = GetTrack(0,i-1)
      local GUID = GetTrackGUID(tr)
      for fx_id = 1, TrackFX_GetCount(tr) do
        local retval, buf = reaper.TrackFX_GetFXName( tr, fx_id-1, '' )
        if not IsInstrument(tr, fx_id-1) and not buf:match('Reaticulate') then
          -- check t
          if FX_state == true then 
            if not (t and t[GUID] and t[GUID][fx_id]) then
              TrackFX_SetEnabled(tr, fx_id-1, FX_state)
            end
           else 
            TrackFX_SetEnabled(tr, fx_id-1, FX_state)
          end
        end
      end
    end
  end
  ---------------------------------------------------------  
  function main()
    local _,_,section_id,command_id = get_action_context()
    glob_state = GetToggleCommandStateEx( section_id, command_id )
    
    if glob_state == -1 or glob_state == 0 then 
      SetStrState() 
      Undo_BeginBlock()
      SetFXState(false)
      SetToggleCommandState( section_id, command_id, 1 )
      RefreshToolbar2(section_id, command_id)
      Undo_EndBlock(scr_title, 0)
     elseif glob_state == 1 then
      local t = GetStrState()
      SetFXState(true, t)
      Undo_BeginBlock()
      SetProjExtState( 0, 'MPL_BYPASSFX', 'state', '' )
      SetToggleCommandState( section_id, command_id, 0 )
      RefreshToolbar2(section_id, command_id)
      Undo_EndBlock(scr_title, 0)
    end
  end
  ---------------------------------------------------------------------
  if VF_CheckReaperVrs(5.95,true)then main() end