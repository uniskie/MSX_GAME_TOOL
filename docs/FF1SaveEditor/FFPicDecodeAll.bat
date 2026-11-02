set src_dir=FF1-1\files
set dst_dir=FF1-1\pic

set btl_src_dir=FF1-1\battle
set btl_dst_dir=FF1-1\pic\battle

for %%i in ("%src_dir%\*.pic") do (
  py FFPicTool.py decode "%%~i" -d "%dst_dir%"
)

for %%i in ("%btl_src_dir%\*.pic") do (
  py FFPicTool.py decode "%%~i" -d "%btl_dst_dir%"
)

timeout /t 10
