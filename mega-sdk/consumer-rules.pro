# The public Java API refers to SWIG-generated classes by name. Keep them when
# consumers enable shrinking or obfuscation.
-keep class nz.mega.sdk.** { *; }
