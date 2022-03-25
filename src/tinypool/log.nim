import std/logging

template debug*(message: string) =
  {.cast(gcsafe).}:
    when defined(enableTinyPoolLogging):
      debug message


template notice*(message: string) =
  {.cast(gcsafe).}:
    when defined(enableTinyPoolLogging):
      notice message


template warn*(message: string) =
  {.cast(gcsafe).}:
    when defined(enableTinyPoolLogging):
      warn message


template error*(message: string) =
  {.cast(gcsafe).}:
    when defined(enableTinyPoolLogging):
      error message


template fatal*(message: string) =
  {.cast(gcsafe).}:
    when defined(enableTinyPoolLogging):
      fatal message
  
