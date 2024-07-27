# DiagSoup



# Architecture Design Records
- all list-wrappers are classes, as they need to be reference-types, so that their state and mutations are maintained as they be passed to other methods
- most classes and props are left open-ended and public, as the intention is to not have unnecessary restriction for the developers to use this library and it is too early to decide on which usage is allowed and which is not
