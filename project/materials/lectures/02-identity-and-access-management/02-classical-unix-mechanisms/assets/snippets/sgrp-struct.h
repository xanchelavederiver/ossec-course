@@ 36
/* Structure of the group file.  */
struct sgrp
  {
    char *sg_namp;		/* Group name.  */
    char *sg_passwd;		/* Encrypted password.  */
    char **sg_adm;		/* Group administrator list.  */
    char **sg_mem;		/* Group member list.  */
  };
