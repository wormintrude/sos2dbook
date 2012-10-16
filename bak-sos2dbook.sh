#!/bin/bash

# Script para parsear reportes SOS y generar documentos en publican [DocBook]

# TO DO
# -----
# - [DONE] Que pasa si el dbook_title ya existe como DocBook - Lo borramos ? Abortamos ?
# - Las variables en autores_file no soportan espacios [fixme]
# - Los paths a los sources estan hardcodeados, deberian pasar como argumentos [fixme]
# - [DONE] En doctype_header el % BOOK_ENTITIES SYSTEM tiene que reflejar el nombre del Book
# - El brand esta harcodeado, deberia pasarse como argumento [fixme]
# - El dbook_title esta harcodeado, deberia pasarse como argumento [fixme]
# - [DONE] Los 'headers' puede que sean solamente aplicables al Authors_Group.xml
# - El metodo dbook_create() no tiene validacion - IMPORTANTE! [fixme]
# - Metodo para descomprimir solo contempla .tar.xz - IMPORTANTE! [fixme]
# - Los SOS reports no tienen /etc/passwd para sacar usuarios agregados [addme]
# - Los SOS reports no tienen una manera de ver software instalado _puntualmente_ para ese deployment / proyecto [addme]
# - Diagrama de la solucion por separado o metido adentro de alguna otra funcion ?
# - Bonds y cualquier tipo de red != ethX [addme]


## Definiciones
# Nombre del DocBook | Es el nombre del cliente para que quede 'bonito' el titulo
dbook_title="Von_Braun_Rockets" # Idealmente seria $1

# Headers
xml_header="<?xml version='1.0' encoding='utf-8' ?>"
doctype_header="<!DOCTYPE <replaceme> PUBLIC \"-//OASIS//DTD DocBook XML V4.5//EN\" \"http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd\" [<!ENTITY % BOOK_ENTITIES SYSTEM \"$dbook_title.ent\"> %BOOK_ENTITIES;]>"
autores_doctype_header=`echo $doctype_header | sed 's/<replaceme>/authorgroup/'`
bookinfo_doctype_header=`echo $doctype_header | sed 's/<replaceme>/bookinfo/'`
book_doctype_header=`echo $doctype_header | sed 's/<replaceme>/book/'`
chapter_doctype_header=`echo $doctype_header | sed 's/<replaceme>/chapter/'`
preface_doctype_header=`echo $doctype_header | sed 's/<replaceme>/preface/'`
revhist_doctype_header=`echo $doctupe_header | sed 's/<replaceme>/appendix/'`
title_doctype_header=`echo $doctype_header | sed 's/<replaceme>/book/'`

# Definiciones del publican.cfg
xml_lang=en-US
dbook_type=Book
brand=RedHat

# PATHs
publican_test_dir=/home/$(whoami)/Documents/publican-test
dbook_root=$publican_test_dir/$dbook_title
dbook_data_dir=$publican_test_dir/$dbook_title/$xml_lang
dbook_build_dir=$publican_test_dir/$dbook_title/tmp
dbook_autores_file=$dbook_data_dir/Author_Group.xml
dbook_info_file=$dbook_data_dir/Book_Info.xml
dbook_chapter_file=$dbook_data_dir/Chapter.xml
dbook_preface_file=$dbook_data_dir/Preface.xml
dbook_revisionh_file=$dbook_data_dir/Revision_History.xml
dbook_ent_file=$dbook_data_dir/$dbook_title.ent
dbook_include_file=$dbook_data_dir/$dbook_title.xml
autores_file=./autores.lista
sos_dir=./sosreports

## Tratamiento de los reportes SOS
decompress_sos(){
  for i in `ls $sos_dir/*.tar.xz`; do
    echo "Descomprimiendo $i"
    tar xf $i -C $sos_dir/ &>/dev/null
  done
}

archive_sos(){
  tar cfvz ./sos-tarball.tar.gz $sos_dir/*.tar.xz &>/dev/null
}

remove_sos_xz(){
  rm -f $sos_dir/*.tar.xz &>/dev/null
}

## Elementos dinamicos del DocBook

# Creacion del DocBook 
dbook_create(){
  create_cmd="publican create"
  cd $publican_test_dir &>/dev/null
  $create_cmd --name $dbook_title --lang $xml_lang --brand $brand --type $dbook_type &>/dev/null
  cd - >/dev/null
}

# XML Autores
autores_create(){
  s_first(){
    local first=$(grep -A 5 Autor$1 $autores_file | grep -v Autor | grep first | awk '{print $3}')
    echo $first
  }

  s_last(){
    local last=$(grep -A 5 Autor$1 $autores_file | grep -v Autor | grep last | awk '{print $3}')
    echo $last
  }

  s_orgname(){
    local orgname=$(grep -A 5 Autor$1 $autores_file | grep -v Autor | grep orgname | awk '{print $3}' | sed 's/_/ /g')
    echo $orgname
  }

  s_orgdiv(){
    local orgdiv=$(grep -A 5 Autor$1 $autores_file | grep -v Autor | grep orgdiv | awk '{print $3}' | sed 's/_/ /g')
    echo $orgdiv
  }

  s_email(){
    local email=$(grep -A 5 Autor$1 $autores_file | grep -v Autor | grep email | awk '{print $3}')
    echo $email
  }
  echo $xml_header
  echo $autores_doctype_header
  echo "<authorgroup>"
  for ((i=1; i<=$(grep "Autor" $autores_file | grep -v "#" | wc -l); i++)) ; do
    echo "  <author>
    <firstname>$(s_first $i)</firstname>
    <surname>$(s_last $i)</surname>
      <affiliation>
        <orgname>$(s_orgname $i)</orgname>
        <orgdiv>$(s_orgdiv $i)</orgdiv>
      </affiliation>
      <email>$(s_email $i)</email>
  </author>"
  done
  echo "</authorgroup>"
}

# Generamos el XML de informacion del DocBook
book_info_create(){
  local dbook_desc="DID (Detailed Implementation Document)" # temp
  local product_name="Red Hat Global Professional Services" # temp
  local product_number="" # temp
  local edition=0.1 # temp
  local pubsnumber=1 # temp - random
  local abstract="Esto es un abstract del problema" # temp
  echo $xml_header
  echo $bookinfo_doctype_header
  echo "<bookinfo id=\"book-$dbook_title-$(echo $dbook_title | sed 's/-/_/g')\"> 
        <title>$(echo $dbook_title | sed 's/_/ /g')</title>
        <subtitle>$dbook_desc</subtitle>
        <productname>$product_name</productname>
        <productnumber>$product_number</productnumber>
        <edition>$edition</edition>
        <pubsnumber>$pubsnumber</pubsnumber>
        <abstract>
                <para>
                       $abstract
                </para>
        </abstract>
        <corpauthor>
                <inlinemediaobject>
                      <imageobject>
                              <imagedata fileref=\"Common_Content/images/title_logo.svg\" format=\"SVG\" />
                      </imageobject>
                </inlinemediaobject>
         </corpauthor>
         <xi:include href=\"Common_Content/Legal_Notice.xml\" xmlns:xi=\"http://www.w3.org/2001/XInclude\" />
         <xi:include href=\"Author_Group.xml\" xmlns:xi=\"http://www.w3.org/2001/XInclude\" />
</bookinfo>"
} 

# Generamos el diagrama de la solucion

sos_gen_diagrama(){
  local diag_img="images/exolgan-diagrama.svg"
  cp /home/reaper/Documents/EXOLGAN/exolgan-diagrama.svg $dbook_data_dir/images/
  local chapter_name="Diagrama"
  echo "Generando $chapter_name.xml"
  touch $dbook_data_dir/$chapter_name.xml
  echo $xml_header >> $dbook_data_dir/$chapter_name.xml
  echo $chapter_doctype_header >> $dbook_data_dir/$chapter_name.xml
  echo "<chapter id=\"$chapter_name\">
        <title>Diagrama de la Solucion</title>
        <section id=\"$chapter_name.grafico\">
                <title>$chapter_name</title>
                <para>
                      <informalfigure>
                        <graphic fileref=\"$diag_img\" scalefit=\"1\" width=\"100%\" contentdepth=\"100%\"/>
                      </informalfigure>
                </para>
        </section>
</chapter>" >> $dbook_data_dir/$chapter_name.xml
}

# Generamos los XML de los Reportes SOS
sos_gen_caps(){
  for i in `ls $sos_dir`; do
    local chapter_name=$(echo $i | cut -d - -f1)
    echo "Generando $chapter_name.xml" 
    touch $dbook_data_dir/$chapter_name.xml
    local sysctl=$sos_dir/$i/etc/sysctl.conf
    local hosts=$sos_dir/$i/etc/hosts
    local rc_local=$sos_dir/$i/etc/rc.d/rc.local
    local profile=$sos_dir/$i/etc/profile
    local chkconfig=$sos_dir/$i/chkconfig
    local ntp_conf=$sos_dir/$i/etc/ntp.conf
    local dns_conf=$sos_dir/$i/etc/resolv.conf
    # table_gen() sirve para NTP y DNS
    table_gen(){
      for i in $(cat $1 | grep -v \# | grep server | awk '{print $2}') ; do 
        echo "<row><entry>Server</entry><entry>$i</entry></row>"
      done
    }
    local netconf_dir=$sos_dir/$i/etc/sysconfig/network-scripts
    netconf_gen(){
      for i in $(ls $netconf_dir/ifcfg-eth*) ; do 
        echo "<row><entry>$(grep DEVICE $i | sed 's/DEVICE=//g' | sed 's/"//g')</entry><entry>$(grep VLAN $i)</entry><entry>$(grep IPADDR $i | sed 's/IPADDR=//g')</entry><entry>$(grep NETMASK $i | sed 's/NETMASK=//g')</entry><entry>$(egrep 'ONBOOT|ONPARENT' $i | sed 's/ONBOOT=//g' | sed 's/ONPARENT=//g')</entry></row>"
      done
    }
    local hostname=$sos_dir/$i/hostname
    local ifconfig=$sos_dir/$i/ifconfig
    local lsb_release=$sos_dir/$i/lsb-release
    local selinux=$sos_dir/$i/etc/selinux/config
    local partitions=$sos_dir/$i/proc/partitions
    local mounts=$sos_dir/$i/proc/mounts
    local etc_lvm_path=$sos_dir/$i/etc/lvm/backup
    # is_lvm - PUEDE FALLAR - Es un asco.
    pv_list(){
      cat $sos_dir/$1/$etc_lvm_path/* | grep -A 2 pv | grep device | awk '{print $3}' | sed 's/"//g'| sed 's/\/dev\///g'
    }
    diskpart_info(){
      for i in $(cat $partitions | egrep -v 'major|dm|cciss|emc' | sed '/\<sd[a-z]\>/g' | sed '/^$/d' | awk '{print $4}'); do
        echo "<row><entry>$i</entry><entry>$(cat $partitions | egrep -v 'major|dm|cciss|emc'| grep $i | awk '{print $3}')</entry><entry>$(grep $i $mounts | awk '{print $2}')</entry><entry></entry></row>"
      done
    }
    echo $xml_header >> $dbook_data_dir/$chapter_name.xml
    echo $chapter_doctype_header >> $dbook_data_dir/$chapter_name.xml
    echo "<chapter id=\"$chapter_name\">
        <title>$chapter_name</title>
        <section id=\"$chapter_name.summary\">
                <title>Servidor</title>
                <para>
                      <table>
                             <title>Servidor</title>
                             <tgroup cols='2'>
                             <thead>
                             <row>
                                  <entry></entry>
                                  <entry></entry>
                             </row>
                             </thead>
                             <tbody>
                                    <row><entry>Nombre</entry><entry>$(cat $hostname)</entry></row>
                                    <row><entry>Direccion IP</entry><entry>$(cat $ifconfig | grep inet | awk '{print $2}' | sed 's/addr://g' | grep -v 127.0.0.1)</entry></row>
                                    <row><entry>Root Password</entry><entry>redhat</entry></row>
                                    <row><entry>Sistema Operativo</entry><entry>$(if [ -e $lsb_release ] ; then cat $lsb_release | awk '{$1=""; print $0}'; else echo "Undefined" ; fi)</entry></row>
                                    <row><entry>Firewall</entry><entry>$(cat $chkconfig | grep iptables | awk '{if ( $5 == "3:on" && $7 == "5:on" ){print "Enabled"} else {print "Disabled"}}')</entry></row>
                                    <row><entry>SELinux</entry><entry>$(if [ -e $selinux ]; then cat $selinux | egrep -v '#|TYPE' | sed '/^$/d' | sed 's/SELINUX=//' | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'; else echo "No hay /etc/selinux/config"; fi)</entry></row>
                             </tbody>
                             </tgroup>
                      </table>
                </para>
        </section>
        <section id=\"$chapter_name.diskpart\">
                <title>Particionado de Discos</title>
                <para>
                      <table>
                             <title>Particionado de Discos</title>
                             <tgroup cols='4'>
                             <thead>
                               <row>
                                    <entry>Slice</entry>
                                    <entry>Size</entry>
                                    <entry>Mount</entry>
                                    <entry>FS</entry>
                               </row>
                             </thead>
                             <tbody>
                                    $(diskpart_info)
                             </tbody>
                             </tgroup>
                      </table>
                </para>
        </section>
        <section id=\"$chapter_name.lvmconf\">
                <title>Configuracion de LVM</title>
                <para>
                      <table>
                             <title>Configuracion de LVM</title>
                             <tgroup cols='6'>
                             <thead>
                               <row>
                                    <entry>PV</entry>
                                    <entry>VG</entry>
                                    <entry>LV</entry>
                                    <entry>Size</entry>
                                    <entry>Mount</entry>
                                    <entry>FS</entry>
                               </row>
                             </thead>
                             <tbody>
                                    <row><entry>PV</entry><entry>PV</entry><entry>PV</entry><entry>PV</entry><entry>PV</entry><entry>PV</entry></row>
                             </tbody>
                             </tgroup>
                      </table>
                </para>
        </section>
        <section id=\"$chapter_name.netconf\">
                <title>Configuracion de Red</title>
                <para>
                      <table>
                             <title>Configuracion de Red</title>
                             <tgroup cols='5'>
                             <thead>
                              <row>
                                <entry>Interfaz</entry>
                                <entry>VLAN Tag</entry>
                                <entry>Direccion IP</entry>
                                <entry>Mascara</entry>
                                <entry>OnBoot</entry>
                              </row>
                             </thead>
                             <tbody>
                                    $(netconf_gen | tr " " "\n")
                             </tbody>
                             </tgroup>
                      </table>
                </para>
        </section>
        <section id=\"$chapter_name.dns\">
                <title>DNS Server</title>
                <para>
                      <table>
                             <title>DNS Server</title>
                             <tgroup cols='2'>
                             <thead>
                              <row>
                                <entry>Campo</entry>
                                <entry>Valor</entry>
                              </row>
                             </thead>
                             <tbody>
                              $(table_gen $dns_conf | tr " " "\n")
                             </tbody>
                             </tgroup>
                      </table>
                </para>
        </section>
        <section id=\"$chapter_name.ntp\">
                <title>NTP Server</title>
                <para>
                      <table>
                             <title>NTP Server</title>
                             <tgroup cols='2'>
                             <thead>
                              <row>
                                <entry>Campo</entry>
                                <entry>Valor</entry>
                              </row>
                             </thead>
                             <tbody>
                              $(table_gen $ntp_conf | tr " " "\n")
                             </tbody>
                             </tgroup>
                      </table>
                </para>
        </section>
        <section id=\"$chapter_name.uname\">
                <title>Sysctl.conf</title>
                <para>
                      <code>/etc/sysctl.conf:</code>
                      <programlisting><![CDATA[$(cat $sysctl | grep -v \# | sed '/^$/d') ]]></programlisting>
                </para>
        </section>
        <section id=\"$chapter_name.hosts\">
                <title>Hosts</title>
                <para>
                      <code>/etc/hosts:</code>
                      <programlisting><![CDATA[$(cat $hosts) ]]></programlisting>
                </para>
        </section>
        <section>
                <title>rc.local</title>
                <para>
                      <code>/etc/rc.d/rc.local:</code>
                      <programlisting><![CDATA[$(cat $rc_local) ]]></programlisting>
                </para>
        </section>
        <section id=\"$chapter_name.profile\">
                <title>Profile</title>
                <para>
                      <code>/etc/profile:</code>
                      <programlisting><![CDATA[$(if [ -e $sos_dir/$i/etc/profile ] ; then cat $profile ; else echo "No se modifico el archivo" ; fi)]]></programlisting>
                </para>
        </section>
        <section id=\"$chapter_name.chkconfig\">
                <title>Startup Services</title>
                <para>
                      <programlisting><![CDATA[$(cat $chkconfig | awk '{print$1}')]]></programlisting>
                </para>
        </section>
</chapter>" >> $dbook_data_dir/$chapter_name.xml
  done
  # El Chapter.xml es nada mas que un template que genera el 'create' de publican
  if [ -e $dbook_data_dir/Chapter.xml ]; then
    rm -f $dbook_data_dir/Chapter.xml &>/dev/null
  fi
}

# Para que publican procese los documentos, hay que incluirlos en el XML que lleva el nombre del DocBook
dbook_include(){
  echo $xml_header
  echo $book_doctype_header
  # <book status="draft"> marca el documento como trabajo en progreso
  echo "<book status=\"draft\">"
  echo "        <xi:include href=\"Book_Info.xml\" xmlns:xi=\"http://www.w3.org/2001/XInclude\"/>"
  echo "        <xi:include href=\"Preface.xml\" xmlns:xi=\"http://www.w3.org/2001/XInclude\" />"
  echo "        <xi:include href=\"Diagrama.xml\" xmlns:xi=\"http://www.w3.org/2001/XInclude\" />"
  for i in `ls $sos_dir | cut -d - -f1`; do
    echo "<xi:include href=\"$i.xml\" xmlns:xi=\"http://www.w3.org/2001/XInclude\" />"
  done
  echo "        <index />"
  echo "</book>"
}

# Build del DocBook
dbook_build(){
  echo "Buildeando DocBook" # debug
  build_cmd="publican build"
  cd $dbook_root &>/dev/null
  $build_cmd --formats=html,html-single,pdf,epub --langs=$xml_lang &>/dev/null
  cd - &>/dev/null
}

## 'Commit' - No hay metodos de validacion [porque vivimos AL LIMITE MWAHAHA]

if [ -e $publican_test_dir/$dbook_title ] ; then
  echo "$dbook_title ya exite. Renombrar este documento o borrar $dbook_title"
  exit 1
fi

# Descomprimimos los Reportes SOS

decompress_sos
archive_sos
remove_sos_xz

# Creamos el DocBook
echo "Generando Templates"
dbook_create

## Generamos los xml's
# Author_Group.xml
echo "Generando Author_Group.xml"
autores_create > $dbook_autores_file

# Book_Info.xml
echo "Generando Book_Info.xml"
book_info_create > $dbook_info_file

# Generamos un capitulo por cada Reporte SOS y uno por el diagrama (?aca o aparte?)
sos_gen_diagrama
sos_gen_caps

# Generamos el 'indice' de XMLs a incluirse
echo "Generando $dbook_title.xml"
dbook_include > $dbook_include_file

# Buildeamos el documento en todos los formatos
dbook_build
if [ -e $dbook_build_dir/$xml_lang/html/index.html ] ; then
  echo "DocBook en formato html generado."
else
  echo "No se genero el DocBook en formato html."
fi
if [ -e $dbook_build_dir/$xml_lang/*.epub ] ; then
  echo "DocBook en formato epub generado."
else
  echo "No se genero el DocBook en formato epub."
fi
if [ -e $dbook_build_dir/$xml_lang/html-single/index.html ] ; then
  echo "DocBook en formato html-single generado."
else
  echo "No se genero el DocBook en formato html-single."
fi
if [ -e $dbook_build_dir/$xml_lang/pdf/*.pdf ] ; then
  echo "DocBook en formato PDF generado."
else
  echo "No se genero el DocBook en formato PDF."
fi

