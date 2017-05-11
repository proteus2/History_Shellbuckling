      subroutine GASP (a, nw, ic, id)
C+---------------------------------------------------------------------+
C|    General Auxiliary Storage Program  (Mass Storage)                |
C|                                                                     |
C|            a(-)  =   Array Involved in Transfer                     |
C|                                                                     |
C|            nw    =   Size of array A                                |
C|                                                                     |
C|            ic    =   0,  Open Existing   file for activity          |
C|                  =  -1,  Open/Initialize file for activity          |
C|                  =  -2,  Close/Release   file from activity         |
C|                  =  -3,  Print statistics of current open file      |
C|                                                                     |
C|                  =   1,  Write A to mass storage                    |
C|                  =   2,  Null operation (error return)              |
C|                  =   3,  Read A from mass storage                   |
C|                                                                     |
C|            id    =   Data block (sector) reference number           |
C|                                                                     |
C|                      (If ID=0 on calls for WRITE, data will         |
C|                       be written at the end of the file)            |
C|                                                                     |
C|                      (The starting (id) is returned as an           |
C|                       arguement for (ic=1) write operations)        |
C+---------------------------------------------------------------------+
C---------------------------------------------------------------------+
C|                   A R G U M E N T S                                 |
C+---------------------------------------------------------------------+
      integer        a(*),     nw,       ic,       id
C+---------------------------------------------------------------------+
C|                   C O M M O N    &    G L O B A L S                 |
C+---------------------------------------------------------------------+
      COMMON/UNITNO/ iu
C+---------------------------------------------------------------------+
C|                   P A R A M E T E R S                               |
C+---------------------------------------------------------------------+

      integer        istor
      save           istor

C+---------------------------------------------------------------------+
C|    PRU  = number of words that MUST match the no. of bytes  PRULIM  |
C|           specified in the block i/o routine BIO.                   |
C+---------------------------------------------------------------------+
C|    NCPW = number of characters per word (parameter within BIO)      |
C+---------------------------------------------------------------------+
C|    CRAY:    PRU  =  512 words  =  4096 bytes  (NCPW = 8)            |
C|    INT64:   PRU  =  256 words  =  2048 bytes  (NCPW = 8)            |
C|    SYS5:    PRU  =  256 words  =  1024 bytes  (NCPW = 4)            |
C|    Other:   PRU  =  128 words  =   512 bytes  (NCPW = 4)            |
C+---------------------------------------------------------------------+
C|    SGI -32  PRU  =  256 words  =  1024 bytes  (NCPW = 4)            |
C|    SGI -64  PRU  =  128 words  =  1024 bytes  (NCPW = 8)            |
C+---------------------------------------------------------------------+
      integer        BUFSIZ
      parameter     (BUFSIZ = 4096)

      integer        PRU
      save           PRU
C+---------------------------------------------------------------------+
C|                   T Y P E    &    D I M E N S I O N                 |
C+---------------------------------------------------------------------+
      character      sfn*128,  opt*2

      integer        fd
      save           fd

      logical        debug
      integer        iblk,     size,     iopen,    next
      save           iblk,     size,     iopen,    next

      integer        idi,      idmx,     ierr,     j,        last
      integer        nblk,     nwds,     nwtogo

      integer        fdu(2),   nextu(2)
      save           fdu,      nextu

      integer        b(BUFSIZ)
C+---------------------------------------------------------------------+
C|                   D A T A                                           |
C+---------------------------------------------------------------------+
      data           debug  / .FALSE. /
      data           iopen  / -1 /
C+---------------------------------------------------------------------+
C|                   L O G I C                                         |
C+---------------------------------------------------------------------+
      not   = 0

c #if (_debug_)
      not   = 6
      debug = .TRUE.
c #endif

      if (iu .eq. 10) then
        lu  = 2
        sfn = 'fort.10'
        lfn = 7
      else
        lu  = 1
        iu  = 11
        sfn = 'fort.11'
        lfn = 7
      endif

      if (debug)                       then
        write (not,7000) nv, ic, id
      endif


      if (ic .eq.  0)                  go to 1000
      if (ic .eq. -1)                  go to 1000

      if (iopen .le. 0)                then
        write (not,8000) ic, id
        call     EXIT (1)
      end if

      if (ic .eq. -2)                  go to 4000
      if (ic .eq. -3)                  go to 5000
      if (ic .eq.  1)                  go to 2000
      if (ic .eq.  3)                  go to 3000

      write (not,8001) ic, id
      call     EXIT (1)
C+---------------------------------------------------------------------+
C|                                                                     |
C|                   O P E N        O p e r a t i o n                  |
C|                                                                     |
C+---------------------------------------------------------------------+
 1000 continue
      nwa     =  1

      if (ic .eq. 0)                   then
        opt     =  ' o'
      else
        opt     =  '  '
      endif

      call       BLKOPN (sfn(1:lfn), opt, fd, PRU, size, ierr)

      if ((PRU .le.      0) .or.
     *    (PRU .gt. BUFSIZ)     )      then
        write (not,8002) sfn(1:lfn), PRU, BUFSIZ
        call     EXIT (3)
      endif

      npru    =  PRU
*     istor   =  size

      last    =  (size + PRU-1) / PRU
      next    =  last + 1

      fdu(lu)   = fd
      nextu(lu) = next

      if (ierr .ne. 0)                 then
        write (not,8003) sfn(1:lfn), fd, PRU, last, ierr
        call     EXIT (4)
      endif

      iopen   =  1

      if (debug)                       then
        write (not,7001) sfn(1:lfn), opt, fd, PRU, size, last, ierr
      endif


      return
C+---------------------------------------------------------------------+
C|                                                                     |
C|                   W R I T E      O p e r a t i o n                  |
C|                                                                     |
C+---------------------------------------------------------------------+
 2000 continue
      fd   = fdu(lu)
      next = nextu(lu)
C+---------------------------------------------------------------------+
C|    iblk  =    number of blocks to write out                         |
C+---------------------------------------------------------------------+
      idi   =     id
      iblk  =    (nw-1)/PRU + 1


      if (id .gt. 0)                   go to 2500
C+---------------------------------------------------------------------+
C|    id = 0,  append A(-) to the end of the existing file             |
C+---------------------------------------------------------------------+
C+---------------------------------------------------------------------+
C|    idi     =  current block (sector) reference number               |
C|    next    =  block number for next append-write (last + 1)         |
C|    istor   =  current total number of words stored                  |
C|    nwds    =  number of words (even multiple of PRU's)              |
C+---------------------------------------------------------------------+
      idi    =   next
      istor  =   istor + nw

      id     =   idi
C+---------------------------------------------------------------------+
C|    id > 0,  Write out A(-) at block number ( id )                   |
C+---------------------------------------------------------------------+
 2500 if (idi .gt. next)               then
        write (not,8004) fd, ic, id, nw, idi, next
        call     EXIT (5)
      endif
C+---------------------------------------------------------------------+
C|    Write out directly from output array  a(-)  the next 'n/PRU'     |
C|    complete blocks of desired data.                                 |
C+---------------------------------------------------------------------+
      nwtogo =   nw
      nblk   =   nwtogo / PRU
      nwds   =   nblk   * PRU

      if (nwds .eq. 0)                 go to 2600

      call       BLKWTR (fd, a(1), nwds, idi, ierr)

      if (debug)                       then
        write  (not,7002) 'WTR', fd, PRU, ic, nwds, nblk
      endif

      if (ierr .ne. 0)                 then
        write (not,8005) fd, ic, id, nw, idi, nblk, nwds,  next,
     *                                              istor, ierr
        call     EXIT (6)
      endif

      idi    =   idi + nblk
      nwtogo =   nwtogo - nwds
C+---------------------------------------------------------------------+
C|      nwds = total number of words transfered in last write          |
C|       idi = starting block number for any aditional writes          |
C|    nwtogo = number of words left to write out from a(-)             |
C+---------------------------------------------------------------------+
 2600 if (nwtogo .le. 0)               go to 2800
C+---------------------------------------------------------------------+
C|    Last portion of desired record not on alignment boundary, hence  |
C|    transfer that portion of output array  a(-)  to this buffer and  |
C|    zero fill remainder of buffer, and write it out.                 |
C+---------------------------------------------------------------------+
      do 2700  j = 1,nwtogo
        b(j) =    a(nwds+j)
 2700 continue

      do 2750  j = nwtogo+1,PRU
        b(j) =  0
 2750 continue

      call       BLKWTR (fd, b(1), PRU, idi, ierr)

      if (debug)                       then
        write  (not,7002) 'WTR', fd, PRU, ic, PRU, idi
      endif

      if (ierr .ne. 0)                 then
        write (not,8005) fd, ic, id, nw, idi, nblk, PRU,   next,
     *                                              istor, ierr
        call     EXIT (7)
      endif

      idi    =   idi + 1

 2800 continue

      next      = MAX (next, idi)
      nextu(lu) = next


      return
C+---------------------------------------------------------------------+
C|                                                                     |
C|                   R E A D        O p e r a t i o n                  |
C|                                                                     |
C+---------------------------------------------------------------------+
 3000 continue
      fd   = fdu(lu)
      next = nextu(lu)
C+---------------------------------------------------------------------+
C|    iblk    =  number of blocks to read in                           |
C+---------------------------------------------------------------------+
      idi   =    id
      iblk  =   (nw-1)/PRU + 1

      if (id .gt. 0)                   go to 3200
C+---------------------------------------------------------------------+
C|    id = 0,  ERROR for Read operation                                |
C+---------------------------------------------------------------------+
      write (not,8006) nw, ic, id

      call     EXIT (8)
C+---------------------------------------------------------------------+
C|    ID > 0,  Check for Reading past the EOF                          |
C+---------------------------------------------------------------------+
 3200 continue
      idmx  =   (idi - 1) + iblk
      if (idmx .lt. next)              go to 3500

      write (not,8007) nw, id, ic, iblk, idmx, next, PRU

      call     EXIT (9)
C+---------------------------------------------------------------------+
C|    ID > 0,  Read in A(-) from block number ( id )                   |
C+---------------------------------------------------------------------+
 3500 continue
C+---------------------------------------------------------------------+
C|    Read into output array  a(-)  the next 'n/64' complete blocks    |
C|    of desired data.  No intermediate transfers are required here.   |
C+---------------------------------------------------------------------+
      nwtogo  =  nw
      nblk    =  nwtogo / PRU
      nwds    =  nblk   * PRU

      if (nwds .eq. 0)                 go to 3600

      call       BLKRDR (fd, a(1), nwds, idi, ierr)

      if (debug)                       then
        write  (not,7002) 'RDR', fd, PRU, ic, nwds, idi
      endif

      if (ierr .ne. 0)                 then
        write (not,8005) fd, ic, id, nw, idi, nblk, nwds,  next,
     *                                              istor, ierr
        call     EXIT (10)
      endif

      idi    =   idi + nblk
C+---------------------------------------------------------------------+
C|      nwds = last word read into array a(-)                          |
C|       idi = next starting block number for any aditional reads      |
C|    nwtogo = number of words left to read in array a(-)              |
C+---------------------------------------------------------------------+
      nwtogo =   nwtogo - nwds

 3600 if (nwtogo .le. 0)               go to 3800
C+---------------------------------------------------------------------+
C|    Last portion of desired record not on alignment boundary, hence  |
C|    read into buffer  b(-)  and transfer residual portion to the     |
C|    output array  a(-)  which will end the transfer of desired data. |
C+---------------------------------------------------------------------+

      call       BLKRDR (fd, b(1), PRU, idi, ierr)

      if (debug)                       then
        write  (not,7002) 'RDR', fd, PRU, ic, PRU, idi
      endif

      if (ierr .ne. 0)                 then
        write (not,8005) fd, ic, id, nw, idi, nblk, PRU,   next,
     *                                              istor, ierr
        call     EXIT (11)
      endif

      idi    =   idi + 1

      do 3700 j = 1,nwtogo
        a(nwds+j) =  b(j)
 3700 continue

 3800 continue



      return
C+---------------------------------------------------------------------+
C|                                                                     |
C|                   C L O S E      O p e r a t i o n                  |
C|                                                                     |
C+---------------------------------------------------------------------+
 4000 continue
      fd     =   fdu(lu)
      opt    =   '  '

      call       BLKCLO (fd, opt, size, ierr)

      if (debug)                       then
        write  (not,7003) opt, fd, PRU
      endif

      if (ierr .ne. 0)                 then
        write (not,8008) fd, nw, ic, id, ierr
        call     EXIT (12)
      endif

      iopen   = -1


      return
C+---------------------------------------------------------------------+
C|                                                                     |
C|                   S T A T U S      O p e r a t i o n                |
C|                                                                     |
C+---------------------------------------------------------------------+
 5000 continue


      call       BLKSTA (fd, ierr)


      if (ierr .ne. 0)                 then
        write (not,8009) fd, nw, ic, id, ierr
        call     EXIT (13)
      endif

      return
C+---------------------------------------------------------------------+
C|                   Fortran Statements                                |
C+---------------------------------------------------------------------+
 7000 format (/,' entered GASP:   size (nv)= ',i8,'  op-code (ic)= ',i2,
     *          '  block (id)= ',i6,
     *        /,' =============',/)
 7001 format (/,' after BLKOPN(---):   sfn  = ',a,'   opt = ',a,
     *        /,' ------------------   fd   = ',i8,'  PRU  = ',i8,
     *        /,22x,'size = ',i8,'  last = ',i8,
     *        /,22x,'ierr = ',i8,/)
 7002 format (' GASP:  BLK',a,':  fd= ',i2,'  PRU= ',i5,'  ic = ',i2,
     *        '  nwds= ',i6,'  nblk= ',i6)
 7003 format (/,' after BLKCLO(---):   opt  = ',a,
     *        /,' ------------------   fd   = ',i8,'  PRU  = ',i8,/)

 8000 format (/' Error in GASP:   Illegal Op-Code   ic = ',I6,
     *           '  id = ',I6,
     *        /'                  must OPEN "scratch" file before ',
     *                            'trying to use it',/)
 8001 format (/' Error in GASP:   Illegal Op-Code   ic = ',I6,
     *           '  id = ',I6/)
 8002 format (/' Error in GASP:   BAD returned buffer size (PRU)',
     *         ' from BLKOPN(---)',
     *        /'                  sfn = ',a,
     *        /'                  PRU = ',I6,'  BUFSIZ = ',I8,/)
 8003 format (/' Error in GASP:   Opening file  sfn = ',a,
     *         '  fd = ',I4,'  PRU = ',I6,'  last = ',I8,
     *         '  ierr = ',Z16/)

 8004 format (//' Error in GASP:   Attempting to WRITE beyond the',
     *          ' End-Of-File:',
     *        //8X,'     fd   ic     id      nw    idi    next',
     *         /8X,I7,I5,2(I7,I8))
 8005 format (//' Error in GASP:   Data Transfer Error Return with:',
     *        //8X,'     fd   ic     id      nw    idi    nblk',
     *          '    nwds   next     istor             ierr',
     *         /8X,I7,I5,2(I7,I8),I8,I7,I10,1X,Z16,2X,'(hex)')
 8006 format (/' Error in GASP:   Illegal Block No. for READ Op',
     *         '   nw = ',I6,'  ic = ',I6,'  id = ',I8/)
 8007 format (/' Error in GASP:   Illegal Record Size for READ Op',
     *        /'    nw = ',I8,'     id = ',I8,'    ic = ',I8,
     *        /'  iblk = ',I8,'   idmx = ',I8,'  next = ',I8,
     *        /'   PRU = ',I8/)
 8008 format (/' ERROR in GASP Block I/O,   fd = ',I6,'   nw = ',I8,
     *         '  ic = ',I8,'  id = ',I8,'  ierr = ',I6/)
 8009 format (/' ERROR in GASP I/O Status,   fd = ',I6,'   nw = ',I8,
     *         '  ic = ',I8,'  id = ',I8,'  ierr = ',I6/)
      end
