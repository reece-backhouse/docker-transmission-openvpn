#!/bin/bash
if [[ "${PEER_DNS,,}" == "true" ]]; then
        NS=
        NS_ROUTES=( )
        DOMAIN=
        SEARCH=
        i=1
        while true ; do
                eval opt=\$foreign_option_${i}
                [ -z "${opt}" ] && break
                if [ "${opt}" != "${opt#dhcp-option DOMAIN *}" ] ; then
                        if [ -z "${DOMAIN}" ] ; then
                                DOMAIN="${opt#dhcp-option DOMAIN *}"
                        else
                                SEARCH="${SEARCH}${SEARCH:+ }${opt#dhcp-option DOMAIN *}"
                        fi
                elif [ "${opt}" != "${opt#dhcp-option DNS *}" ] ; then
                        new_ns="${opt#dhcp-option DNS *}"
                        NS_ROUTES+=( "${new_ns}" )
                        NS="${NS}nameserver ${new_ns}\n"
                fi
                i=$((${i} + 1))
        done
        if [ -n "${NS}" ] ; then
		if [[ "${PEER_DNS_PIN_ROUTES,,}" == "true" ]]; then
			#  Explicitly pin DNS traffic out the tunnel if we received the NS from them.
			for r in "${NS_ROUTES[@]}"; do
				ip route add "$r" dev "${dev}"
			done
		fi
                DNS="# Generated by openvpn for interface ${dev}\n"
                if [ -n "${SEARCH}" ] ; then
                        DNS="${DNS}search ${DOMAIN} ${SEARCH}\n"
                elif [ -n "${DOMAIN}" ]; then
                        DNS="${DNS}domain ${DOMAIN}\n"
                fi
                DNS="${DNS}${NS}"
                if [ -x /sbin/resolvconf ] ; then
                        printf "${DNS}" | /sbin/resolvconf -a "${dev}"
                else
                        # Preserve the existing resolv.conf
                        if [ -e /etc/resolv.conf ] ; then
                                cp /etc/resolv.conf /etc/resolv.conf-"${dev}".sv
                        fi
                        printf "${DNS}" > /etc/resolv.conf
                        chmod 644 /etc/resolv.conf
                fi
        fi
fi

/etc/transmission/start.sh "$@"
[[ -f /opt/privoxy/start.sh && -x /opt/privoxy/start.sh ]] && /opt/privoxy/start.sh

exit 0
